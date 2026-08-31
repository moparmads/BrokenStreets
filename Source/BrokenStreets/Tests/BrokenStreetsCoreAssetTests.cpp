// Copyright Madalin Gavrila. All Rights Reserved.

#if WITH_DEV_AUTOMATION_TESTS

#include "Core/Assets/BSAssetLoadingPolicy.h"
#include "Engine/AssetManagerSettings.h"
#include "Items/Definitions/BSItemDefinition.h"
#include "Misc/AutomationTest.h"
#include "UObject/UnrealType.h"

namespace
{
bool ParseDefinitionId(FAutomationTestBase& Test, const TCHAR* Text, FBSDefinitionId& OutId)
{
	return Test.TestTrue(
		*FString::Printf(TEXT("The definition fixture parses: %s"), Text),
		FBSDefinitionId::TryParse(Text, OutId));
}

FBSItemCatalogEntry MakeCatalogEntry(const TCHAR* IdText, const TCHAR* PackagePath)
{
	FBSItemCatalogEntry Entry;
	Entry.PrimaryAssetId = FPrimaryAssetId::ParseTypeAndName(FString(IdText));
	Entry.PackagePath = PackagePath;
	return Entry;
}
} // namespace

IMPLEMENT_SIMPLE_AUTOMATION_TEST(
	FBrokenStreetsItemDefinitionTest,
	"BrokenStreets.Core.Assets.ItemDefinition",
	EAutomationTestFlags::EditorContext | EAutomationTestFlags::EngineFilter)

bool FBrokenStreetsItemDefinitionTest::RunTest(const FString& Parameters)
{
	bool bPassed = true;
	UBSItemDefinition* Definition = NewObject<UBSItemDefinition>();
	bPassed &= TestNotNull(TEXT("An item definition can be created"), Definition);
	if (Definition == nullptr)
	{
		return false;
	}

	bPassed &= TestFalse(TEXT("An unset item definition has no primary asset identity"), Definition->GetPrimaryAssetId().IsValid());
	bPassed &= TestTrue(TEXT("The item definition is a primary data asset"), Definition->IsA<UPrimaryDataAsset>());

	FBSDefinitionId ItemId;
	bPassed &= ParseDefinitionId(*this, TEXT("item:test_item"), ItemId);
	Definition->DefinitionId = ItemId;
	bPassed &= TestEqual(
		TEXT("The stable definition identity maps exactly to the primary asset identity"),
		Definition->GetPrimaryAssetId(),
		FPrimaryAssetId(UBSItemDefinition::ItemAssetType, TEXT("test_item")));

	FBSDefinitionId WrongTypeId;
	bPassed &= ParseDefinitionId(*this, TEXT("vehicle:test_vehicle"), WrongTypeId);
	Definition->DefinitionId = WrongTypeId;
	bPassed &= TestFalse(TEXT("A non-item definition identity fails closed"), Definition->GetPrimaryAssetId().IsValid());

	const FProperty* WorldMeshProperty = FindFProperty<FProperty>(UBSItemDefinition::StaticClass(), GET_MEMBER_NAME_CHECKED(UBSItemDefinition, WorldMesh));
	const FProperty* IconProperty = FindFProperty<FProperty>(UBSItemDefinition::StaticClass(), GET_MEMBER_NAME_CHECKED(UBSItemDefinition, Icon));
	bPassed &= TestNotNull(TEXT("The optional world mesh is reflected"), WorldMeshProperty);
	bPassed &= TestNotNull(TEXT("The optional UI icon is reflected"), IconProperty);
	if (WorldMeshProperty != nullptr)
	{
		bPassed &= TestEqual(TEXT("The world mesh is assigned only to the World bundle"), WorldMeshProperty->GetMetaData(TEXT("AssetBundles")), FString(TEXT("World")));
	}
	if (IconProperty != nullptr)
	{
		bPassed &= TestEqual(TEXT("The icon is assigned only to the UI bundle"), IconProperty->GetMetaData(TEXT("AssetBundles")), FString(TEXT("UI")));
	}

	return bPassed;
}

IMPLEMENT_SIMPLE_AUTOMATION_TEST(
	FBrokenStreetsAssetLoadingPolicyTest,
	"BrokenStreets.Core.Assets.LoadingPolicy",
	EAutomationTestFlags::EditorContext | EAutomationTestFlags::EngineFilter)

bool FBrokenStreetsAssetLoadingPolicyTest::RunTest(const FString& Parameters)
{
	bool bPassed = true;
	FBSDefinitionId ItemId;
	bPassed &= ParseDefinitionId(*this, TEXT("item:test_item"), ItemId);

	FBSItemDefinitionLoadRequest Request;
	const TArray<FName> ReverseBundles = {UBSItemDefinition::UIBundle, UBSItemDefinition::WorldBundle};
	bPassed &= TestTrue(TEXT("A valid item request accepts both supported bundles"), FBSItemDefinitionLoadRequest::TryCreate(ItemId, ReverseBundles, Request));
	bPassed &= TestTrue(TEXT("The resulting request is valid"), Request.IsValid());
	bPassed &= TestEqual(TEXT("The request retains its stable definition identity"), Request.GetDefinitionId(), ItemId);
	bPassed &= TestEqual(TEXT("The request contains exactly two bundles"), Request.GetBundles().Num(), 2);
	if (Request.GetBundles().Num() == 2)
	{
		bPassed &= TestEqual(TEXT("Bundle order is normalized with World first"), Request.GetBundles()[0], UBSItemDefinition::WorldBundle);
		bPassed &= TestEqual(TEXT("Bundle order is normalized with UI second"), Request.GetBundles()[1], UBSItemDefinition::UIBundle);
	}

	const TArray<FName> NoBundles;
	bPassed &= TestTrue(TEXT("A definition-only request is valid"), FBSItemDefinitionLoadRequest::TryCreate(ItemId, NoBundles, Request));
	bPassed &= TestEqual(TEXT("A definition-only request has no dependency bundles"), Request.GetBundles().Num(), 0);

	const TArray<FName> DuplicateBundles = {UBSItemDefinition::WorldBundle, UBSItemDefinition::WorldBundle};
	bPassed &= TestFalse(TEXT("Duplicate bundles are rejected"), FBSItemDefinitionLoadRequest::TryCreate(ItemId, DuplicateBundles, Request));
	bPassed &= TestFalse(TEXT("A rejected request clears prior state"), Request.IsValid());

	const TArray<FName> UnknownBundles = {TEXT("Gameplay")};
	bPassed &= TestFalse(TEXT("Unknown bundles are rejected"), FBSItemDefinitionLoadRequest::TryCreate(ItemId, UnknownBundles, Request));
	const TArray<FName> EmptyBundle = {NAME_None};
	bPassed &= TestFalse(TEXT("An empty bundle name is rejected"), FBSItemDefinitionLoadRequest::TryCreate(ItemId, EmptyBundle, Request));

	FBSDefinitionId WrongTypeId;
	bPassed &= ParseDefinitionId(*this, TEXT("vehicle:test_vehicle"), WrongTypeId);
	bPassed &= TestFalse(TEXT("A non-item identity is rejected"), FBSItemDefinitionLoadRequest::TryCreate(WrongTypeId, NoBundles, Request));

	TSharedPtr<FStreamableHandle> Handle;
	const FBSResult InvalidResult = FBSAssetLoadingPolicy::RequestAsync(Request, FStreamableDelegate(), Handle);
	bPassed &= TestTrue(TEXT("An invalid load request is deliberately rejected"), InvalidResult.IsRejected());
	bPassed &= TestEqual(TEXT("The invalid-request error is stable"), InvalidResult.GetErrorCode().ToString(), FString(TEXT("assets.invalid_request")));
	bPassed &= TestFalse(TEXT("An invalid request produces no output handle"), Handle.IsValid());

	FBSDefinitionId MissingId;
	bPassed &= ParseDefinitionId(*this, TEXT("item:missing_test_item"), MissingId);
	bPassed &= TestTrue(TEXT("The missing-item request itself is valid"), FBSItemDefinitionLoadRequest::TryCreate(MissingId, NoBundles, Request));
	const FBSResult MissingResult = FBSAssetLoadingPolicy::RequestAsync(Request, FStreamableDelegate(), Handle);
	bPassed &= TestTrue(TEXT("An unregistered definition is deliberately rejected"), MissingResult.IsRejected());
	bPassed &= TestEqual(TEXT("The missing-definition error is stable"), MissingResult.GetErrorCode().ToString(), FString(TEXT("assets.definition_not_found")));
	bPassed &= TestFalse(TEXT("A missing definition produces no load handle"), Handle.IsValid());
	bPassed &= TestEqual(TEXT("Releasing a non-item identity has no effect"), FBSAssetLoadingPolicy::Release(WrongTypeId), 0);
	bPassed &= TestNull(TEXT("Finding a non-item identity never loads an object"), FBSAssetLoadingPolicy::FindLoaded(WrongTypeId));

	return bPassed;
}

IMPLEMENT_SIMPLE_AUTOMATION_TEST(
	FBrokenStreetsAssetConfigurationTest,
	"BrokenStreets.Core.Assets.Configuration",
	EAutomationTestFlags::EditorContext | EAutomationTestFlags::EngineFilter)

bool FBrokenStreetsAssetConfigurationTest::RunTest(const FString& Parameters)
{
	bool bPassed = true;
	const UAssetManagerSettings* Settings = GetDefault<UAssetManagerSettings>();
	bPassed &= TestNotNull(TEXT("Asset Manager settings are available"), Settings);
	if (Settings == nullptr)
	{
		return false;
	}

	const FPrimaryAssetTypeInfo* ItemTypeInfo = nullptr;
	int32 ItemRuleCount = 0;
	for (const FPrimaryAssetTypeInfo& TypeInfo : Settings->PrimaryAssetTypesToScan)
	{
		if (TypeInfo.PrimaryAssetType == UBSItemDefinition::ItemAssetType)
		{
			ItemTypeInfo = &TypeInfo;
			++ItemRuleCount;
		}
	}
	bPassed &= TestEqual(TEXT("Exactly one item primary asset rule is configured"), ItemRuleCount, 1);
	if (ItemTypeInfo != nullptr)
	{
		bPassed &= TestEqual(TEXT("The item rule uses the native item definition class"), ItemTypeInfo->GetAssetBaseClass().ToSoftObjectPath().ToString(), FString(TEXT("/Script/BrokenStreets.BSItemDefinition")));
		bPassed &= TestFalse(TEXT("Item definitions are native assets rather than Blueprint classes"), ItemTypeInfo->bHasBlueprintClasses);
		bPassed &= TestFalse(TEXT("Item definitions are available at runtime"), ItemTypeInfo->bIsEditorOnly);
		bPassed &= TestEqual(TEXT("The item rule has one catalog root"), ItemTypeInfo->GetDirectories().Num(), 1);
		if (ItemTypeInfo->GetDirectories().Num() == 1)
		{
			bPassed &= TestEqual(TEXT("The item catalog root is exact"), ItemTypeInfo->GetDirectories()[0].Path, FString(FBSItemCatalogAudit::ItemDefinitionRoot));
		}
		bPassed &= TestEqual(TEXT("No individual item assets bypass the catalog root"), ItemTypeInfo->GetSpecificAssets().Num(), 0);
		bPassed &= TestEqual(TEXT("The item rule priority is explicit"), ItemTypeInfo->Rules.Priority, 0);
		bPassed &= TestEqual(TEXT("The item rule uses the default chunk"), ItemTypeInfo->Rules.ChunkId, -1);
		bPassed &= TestTrue(TEXT("The item rule manages dependencies recursively"), ItemTypeInfo->Rules.bApplyRecursively);
		bPassed &= TestEqual(TEXT("All registered item definitions are always cooked"), ItemTypeInfo->Rules.CookRule, EPrimaryAssetCookRule::AlwaysCook);
	}
	bPassed &= TestFalse(TEXT("The manager cannot invent primary asset identities"), Settings->bShouldManagerDetermineTypeAndName);
	bPassed &= TestFalse(TEXT("The editor cannot guess primary asset identities"), Settings->bShouldGuessTypeAndNameInEditor);
	bPassed &= TestTrue(TEXT("Invalid primary assets emit warnings"), Settings->bShouldWarnAboutInvalidAssets);

	FBSItemCatalogAuditResult AuditResult;
	bPassed &= TestTrue(TEXT("The registered unloaded item catalog passes"), FBSItemCatalogAudit::AuditRegistered(AuditResult));
	bPassed &= TestTrue(TEXT("A passing catalog audit is valid"), AuditResult.IsValid());

	const TArray<FBSItemCatalogEntry> ValidEntries = {
		MakeCatalogEntry(TEXT("item:apple"), TEXT("/Game/BS/Definitions/Items/Food")),
		MakeCatalogEntry(TEXT("item:water_bottle"), TEXT("/Game/BS/Definitions/Items/Drinks")),
	};
	bPassed &= TestTrue(TEXT("A valid unloaded catalog fixture passes"), FBSItemCatalogAudit::AuditEntries(ValidEntries, AuditResult));
	bPassed &= TestEqual(TEXT("The audit counts definitions without loading them"), AuditResult.GetDefinitionCount(), 2);

	const TArray<FBSItemCatalogEntry> WrongTypeEntries = {MakeCatalogEntry(TEXT("vehicle:sedan"), TEXT("/Game/BS/Definitions/Items/Vehicles"))};
	bPassed &= TestFalse(TEXT("A wrong primary asset type fails"), FBSItemCatalogAudit::AuditEntries(WrongTypeEntries, AuditResult));
	bPassed &= TestEqual(TEXT("The wrong-type issue is exact"), AuditResult.GetIssue(), EBSItemCatalogAuditIssue::WrongPrimaryAssetType);

	const TArray<FBSItemCatalogEntry> InvalidIdEntries = {MakeCatalogEntry(TEXT("item:BadName"), TEXT("/Game/BS/Definitions/Items/Test"))};
	bPassed &= TestFalse(TEXT("A noncanonical primary asset identity fails"), FBSItemCatalogAudit::AuditEntries(InvalidIdEntries, AuditResult));
	bPassed &= TestEqual(TEXT("The invalid-identity issue is exact"), AuditResult.GetIssue(), EBSItemCatalogAuditIssue::InvalidPrimaryAssetId);

	const TArray<FBSItemCatalogEntry> DuplicateEntries = {
		MakeCatalogEntry(TEXT("item:apple"), TEXT("/Game/BS/Definitions/Items/Food")),
		MakeCatalogEntry(TEXT("item:apple"), TEXT("/Game/BS/Definitions/Items/Other")),
	};
	bPassed &= TestFalse(TEXT("A duplicate primary asset identity fails"), FBSItemCatalogAudit::AuditEntries(DuplicateEntries, AuditResult));
	bPassed &= TestEqual(TEXT("The duplicate issue is exact"), AuditResult.GetIssue(), EBSItemCatalogAuditIssue::DuplicatePrimaryAssetId);

	const TArray<FBSItemCatalogEntry> WrongPathEntries = {MakeCatalogEntry(TEXT("item:apple"), TEXT("/Game/Items"))};
	bPassed &= TestFalse(TEXT("An item outside the catalog root fails"), FBSItemCatalogAudit::AuditEntries(WrongPathEntries, AuditResult));
	bPassed &= TestEqual(TEXT("The invalid-path issue is exact"), AuditResult.GetIssue(), EBSItemCatalogAuditIssue::InvalidPackagePath);
	bPassed &= TestEqual(TEXT("Audit issues have stable machine names"), FString(FBSItemCatalogAudit::GetStableName(AuditResult.GetIssue())), FString(TEXT("invalid_package_path")));

	return bPassed;
}

#endif // WITH_DEV_AUTOMATION_TESTS
