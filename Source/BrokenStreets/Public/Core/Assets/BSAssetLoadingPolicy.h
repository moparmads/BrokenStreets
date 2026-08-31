// Copyright Madalin Gavrila. All Rights Reserved.

#pragma once

#include "CoreMinimal.h"
#include "Core/Identity/BSIdentifiers.h"
#include "Core/Results/BSResult.h"
#include "Engine/StreamableManager.h"

class UBSItemDefinition;

/** Validated request for an item definition and a bounded set of dependency bundles. */
class BROKENSTREETS_API FBSItemDefinitionLoadRequest final
{
public:
	static constexpr int32 MaxBundles = 2;

	FBSItemDefinitionLoadRequest() = default;

	/** Accepts only item identities and the unique World/UI bundle vocabulary. */
	[[nodiscard]] static bool TryCreate(
		const FBSDefinitionId& DefinitionId,
		TConstArrayView<FName> Bundles,
		FBSItemDefinitionLoadRequest& OutRequest);

	[[nodiscard]] bool IsValid() const;
	[[nodiscard]] const FBSDefinitionId& GetDefinitionId() const;
	[[nodiscard]] const TArray<FName>& GetBundles() const;

	void Reset();

private:
	FBSDefinitionId DefinitionIdValue;
	TArray<FName> BundleValues;
};

/** Explicit asynchronous item-loading gateway. It never mutates gameplay state. */
class BROKENSTREETS_API FBSAssetLoadingPolicy final
{
public:
	[[nodiscard]] static FBSResult RequestAsync(
		const FBSItemDefinitionLoadRequest& Request,
		FStreamableDelegate Completion,
		TSharedPtr<FStreamableHandle>& OutHandle);

	/** Releases Asset Manager ownership for a previously requested definition. */
	[[nodiscard]] static int32 Release(const FBSDefinitionId& DefinitionId);

	/** Returns an already loaded definition without causing synchronous loading. */
	[[nodiscard]] static const UBSItemDefinition* FindLoaded(const FBSDefinitionId& DefinitionId);
};

/** One unloaded registry record used by deterministic catalog auditing. */
struct BROKENSTREETS_API FBSItemCatalogEntry final
{
	FPrimaryAssetId PrimaryAssetId;
	FString PackagePath;
};

enum class EBSItemCatalogAuditIssue : uint8
{
	None,
	AssetManagerUnavailable,
	ItemTypeNotRegistered,
	InvalidPrimaryAssetId,
	WrongPrimaryAssetType,
	DuplicatePrimaryAssetId,
	InvalidPackagePath,
};

struct BROKENSTREETS_API FBSItemCatalogAuditResult final
{
	[[nodiscard]] bool IsValid() const;
	[[nodiscard]] EBSItemCatalogAuditIssue GetIssue() const;
	[[nodiscard]] int32 GetDefinitionCount() const;
	[[nodiscard]] const FPrimaryAssetId& GetProblemId() const;

	void Reset();

private:
	friend class FBSItemCatalogAudit;

	EBSItemCatalogAuditIssue Issue = EBSItemCatalogAuditIssue::AssetManagerUnavailable;
	int32 DefinitionCount = 0;
	FPrimaryAssetId ProblemId;
};

/** Audits Asset Registry metadata only; item assets are never loaded by this operation. */
class BROKENSTREETS_API FBSItemCatalogAudit final
{
public:
	static const TCHAR* ItemDefinitionRoot;

	[[nodiscard]] static bool AuditRegistered(FBSItemCatalogAuditResult& OutResult);
	[[nodiscard]] static bool AuditEntries(
		TConstArrayView<FBSItemCatalogEntry> Entries,
		FBSItemCatalogAuditResult& OutResult);
	[[nodiscard]] static const TCHAR* GetStableName(EBSItemCatalogAuditIssue Issue);
};
