// Copyright Madalin Gavrila. All Rights Reserved.

#include "Core/Assets/BSAssetLoadingPolicy.h"

#include "AssetRegistry/AssetData.h"
#include "Engine/AssetManager.h"
#include "Items/Definitions/BSItemDefinition.h"

namespace
{
FBSResult MakeResultWithError(const TCHAR* ErrorText, const bool bRejected)
{
	FBSErrorCode ErrorCode;
	FBSResult Result;
	if (!FBSErrorCode::TryParse(ErrorText, ErrorCode))
	{
		return Result;
	}

	if (bRejected)
	{
		const bool bCreated = FBSResult::TryCreateRejected(ErrorCode, Result);
		check(bCreated);
	}
	else
	{
		const bool bCreated = FBSResult::TryCreateFailed(ErrorCode, Result);
		check(bCreated);
	}

	return Result;
}

bool IsCanonicalItemId(const FBSDefinitionId& DefinitionId)
{
	return DefinitionId.IsValid()
		&& DefinitionId.ToPrimaryAssetId().PrimaryAssetType == UBSItemDefinition::ItemAssetType;
}

bool IsAllowedItemBundle(const FName Bundle)
{
	return Bundle == UBSItemDefinition::WorldBundle || Bundle == UBSItemDefinition::UIBundle;
}

} // namespace

const TCHAR* FBSItemCatalogAudit::ItemDefinitionRoot = TEXT("/Game/BS/Definitions/Items");

bool FBSItemDefinitionLoadRequest::TryCreate(
	const FBSDefinitionId& DefinitionId,
	const TConstArrayView<FName> Bundles,
	FBSItemDefinitionLoadRequest& OutRequest)
{
	OutRequest.Reset();

	if (!IsCanonicalItemId(DefinitionId) || Bundles.Num() > MaxBundles)
	{
		return false;
	}

	bool bWantsWorld = false;
	bool bWantsUI = false;
	for (const FName Bundle : Bundles)
	{
		if (Bundle.IsNone() || !IsAllowedItemBundle(Bundle))
		{
			return false;
		}

		bool& bSeen = Bundle == UBSItemDefinition::WorldBundle ? bWantsWorld : bWantsUI;
		if (bSeen)
		{
			return false;
		}
		bSeen = true;
	}

	OutRequest.DefinitionIdValue = DefinitionId;
	if (bWantsWorld)
	{
		OutRequest.BundleValues.Add(UBSItemDefinition::WorldBundle);
	}
	if (bWantsUI)
	{
		OutRequest.BundleValues.Add(UBSItemDefinition::UIBundle);
	}
	return true;
}

bool FBSItemDefinitionLoadRequest::IsValid() const
{
	FBSItemDefinitionLoadRequest Normalized;
	return TryCreate(DefinitionIdValue, BundleValues, Normalized)
		&& Normalized.BundleValues == BundleValues;
}

const FBSDefinitionId& FBSItemDefinitionLoadRequest::GetDefinitionId() const
{
	return DefinitionIdValue;
}

const TArray<FName>& FBSItemDefinitionLoadRequest::GetBundles() const
{
	return BundleValues;
}

void FBSItemDefinitionLoadRequest::Reset()
{
	DefinitionIdValue.Reset();
	BundleValues.Reset();
}

FBSResult FBSAssetLoadingPolicy::RequestAsync(
	const FBSItemDefinitionLoadRequest& Request,
	FStreamableDelegate Completion,
	TSharedPtr<FStreamableHandle>& OutHandle)
{
	OutHandle.Reset();
	if (!Request.IsValid())
	{
		return MakeResultWithError(TEXT("assets.invalid_request"), true);
	}

	UAssetManager* AssetManager = UAssetManager::GetIfInitialized();
	if (AssetManager == nullptr)
	{
		return MakeResultWithError(TEXT("assets.manager_unavailable"), false);
	}

	const FPrimaryAssetId PrimaryAssetId = Request.GetDefinitionId().ToPrimaryAssetId();
	FAssetData AssetData;
	if (!AssetManager->GetPrimaryAssetData(PrimaryAssetId, AssetData))
	{
		return MakeResultWithError(TEXT("assets.definition_not_found"), true);
	}

	OutHandle = AssetManager->LoadPrimaryAsset(PrimaryAssetId, Request.GetBundles(), MoveTemp(Completion));
	if (!OutHandle.IsValid() && AssetManager->GetPrimaryAssetObject(PrimaryAssetId) == nullptr)
	{
		return MakeResultWithError(TEXT("assets.request_failed"), false);
	}

	return FBSResult::Succeeded();
}

int32 FBSAssetLoadingPolicy::Release(const FBSDefinitionId& DefinitionId)
{
	UAssetManager* AssetManager = UAssetManager::GetIfInitialized();
	return AssetManager != nullptr && IsCanonicalItemId(DefinitionId)
		? AssetManager->UnloadPrimaryAsset(DefinitionId.ToPrimaryAssetId())
		: 0;
}

const UBSItemDefinition* FBSAssetLoadingPolicy::FindLoaded(const FBSDefinitionId& DefinitionId)
{
	const UAssetManager* AssetManager = UAssetManager::GetIfInitialized();
	return AssetManager != nullptr && IsCanonicalItemId(DefinitionId)
		? AssetManager->GetPrimaryAssetObject<UBSItemDefinition>(DefinitionId.ToPrimaryAssetId())
		: nullptr;
}

bool FBSItemCatalogAuditResult::IsValid() const
{
	return Issue == EBSItemCatalogAuditIssue::None && DefinitionCount >= 0 && !ProblemId.IsValid();
}

EBSItemCatalogAuditIssue FBSItemCatalogAuditResult::GetIssue() const
{
	return Issue;
}

int32 FBSItemCatalogAuditResult::GetDefinitionCount() const
{
	return DefinitionCount;
}

const FPrimaryAssetId& FBSItemCatalogAuditResult::GetProblemId() const
{
	return ProblemId;
}

void FBSItemCatalogAuditResult::Reset()
{
	Issue = EBSItemCatalogAuditIssue::AssetManagerUnavailable;
	DefinitionCount = 0;
	ProblemId = FPrimaryAssetId();
}

bool FBSItemCatalogAudit::AuditRegistered(FBSItemCatalogAuditResult& OutResult)
{
	OutResult.Reset();
	const UAssetManager* AssetManager = UAssetManager::GetIfInitialized();
	if (AssetManager == nullptr)
	{
		return false;
	}

	FPrimaryAssetTypeInfo TypeInfo;
	if (!AssetManager->GetPrimaryAssetTypeInfo(UBSItemDefinition::ItemAssetType, TypeInfo))
	{
		OutResult.Issue = EBSItemCatalogAuditIssue::ItemTypeNotRegistered;
		return false;
	}

	TArray<FAssetData> AssetDataList;
	AssetManager->GetPrimaryAssetDataList(UBSItemDefinition::ItemAssetType, AssetDataList);
	TArray<FBSItemCatalogEntry> Entries;
	Entries.Reserve(AssetDataList.Num());
	for (const FAssetData& AssetData : AssetDataList)
	{
		FBSItemCatalogEntry& Entry = Entries.AddDefaulted_GetRef();
		Entry.PrimaryAssetId = AssetData.GetPrimaryAssetId();
		Entry.PackagePath = AssetData.PackagePath.ToString();
	}

	return AuditEntries(Entries, OutResult);
}

bool FBSItemCatalogAudit::AuditEntries(
	const TConstArrayView<FBSItemCatalogEntry> Entries,
	FBSItemCatalogAuditResult& OutResult)
{
	OutResult.Reset();
	OutResult.DefinitionCount = Entries.Num();
	TSet<FPrimaryAssetId> SeenIds;

	for (const FBSItemCatalogEntry& Entry : Entries)
	{
		if (!Entry.PrimaryAssetId.IsValid())
		{
			OutResult.Issue = EBSItemCatalogAuditIssue::InvalidPrimaryAssetId;
			OutResult.ProblemId = Entry.PrimaryAssetId;
			return false;
		}
		if (Entry.PrimaryAssetId.PrimaryAssetType != UBSItemDefinition::ItemAssetType)
		{
			OutResult.Issue = EBSItemCatalogAuditIssue::WrongPrimaryAssetType;
			OutResult.ProblemId = Entry.PrimaryAssetId;
			return false;
		}

		FBSDefinitionId DefinitionId;
		if (!FBSDefinitionId::TryParse(Entry.PrimaryAssetId.ToString(), DefinitionId)
			|| DefinitionId.ToPrimaryAssetId() != Entry.PrimaryAssetId)
		{
			OutResult.Issue = EBSItemCatalogAuditIssue::InvalidPrimaryAssetId;
			OutResult.ProblemId = Entry.PrimaryAssetId;
			return false;
		}
		if (SeenIds.Contains(Entry.PrimaryAssetId))
		{
			OutResult.Issue = EBSItemCatalogAuditIssue::DuplicatePrimaryAssetId;
			OutResult.ProblemId = Entry.PrimaryAssetId;
			return false;
		}
		SeenIds.Add(Entry.PrimaryAssetId);

		const FString RequiredPrefix = FString(ItemDefinitionRoot) + TEXT("/");
		if (!Entry.PackagePath.StartsWith(RequiredPrefix, ESearchCase::CaseSensitive))
		{
			OutResult.Issue = EBSItemCatalogAuditIssue::InvalidPackagePath;
			OutResult.ProblemId = Entry.PrimaryAssetId;
			return false;
		}
	}

	OutResult.Issue = EBSItemCatalogAuditIssue::None;
	OutResult.ProblemId = FPrimaryAssetId();
	return true;
}

const TCHAR* FBSItemCatalogAudit::GetStableName(const EBSItemCatalogAuditIssue Issue)
{
	switch (Issue)
	{
	case EBSItemCatalogAuditIssue::None:
		return TEXT("none");
	case EBSItemCatalogAuditIssue::AssetManagerUnavailable:
		return TEXT("asset_manager_unavailable");
	case EBSItemCatalogAuditIssue::ItemTypeNotRegistered:
		return TEXT("item_type_not_registered");
	case EBSItemCatalogAuditIssue::InvalidPrimaryAssetId:
		return TEXT("invalid_primary_asset_id");
	case EBSItemCatalogAuditIssue::WrongPrimaryAssetType:
		return TEXT("wrong_primary_asset_type");
	case EBSItemCatalogAuditIssue::DuplicatePrimaryAssetId:
		return TEXT("duplicate_primary_asset_id");
	case EBSItemCatalogAuditIssue::InvalidPackagePath:
		return TEXT("invalid_package_path");
	default:
		return TEXT("unknown");
	}
}
