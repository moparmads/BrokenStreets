// Copyright Madalin Gavrila. All Rights Reserved.

#if WITH_DEV_AUTOMATION_TESTS

#include "Core/Identity/BSIdentifiers.h"
#include "Core/Tags/BSGameplayTags.h"
#include "GameplayTagsSettings.h"
#include "Misc/AutomationTest.h"
#include "Serialization/MemoryReader.h"
#include "Serialization/MemoryWriter.h"

#include <type_traits>

static_assert(!std::is_constructible_v<FBSDefinitionId, FBSInstanceId>);
static_assert(!std::is_constructible_v<FBSInstanceId, FBSDefinitionId>);
static_assert(!std::is_convertible_v<FPrimaryAssetId, FBSDefinitionId>);
static_assert(!std::is_convertible_v<FGuid, FBSInstanceId>);

IMPLEMENT_SIMPLE_AUTOMATION_TEST(
	FBrokenStreetsDefinitionIdTest,
	"BrokenStreets.Core.Identity.DefinitionId",
	EAutomationTestFlags::EditorContext | EAutomationTestFlags::EngineFilter)

bool FBrokenStreetsDefinitionIdTest::RunTest(const FString& Parameters)
{
	bool bPassed = true;
	FBSDefinitionId DefinitionId;

	bPassed &= TestFalse(TEXT("The default DefinitionId is invalid"), DefinitionId.IsValid());
	bPassed &= TestTrue(
		TEXT("Canonical DefinitionId text parses"),
		FBSDefinitionId::TryParse(TEXT("item:water_bottle"), DefinitionId));
	bPassed &= TestTrue(TEXT("A parsed DefinitionId is valid"), DefinitionId.IsValid());
	bPassed &= TestEqual(
		TEXT("DefinitionId preserves canonical text"),
		DefinitionId.ToString(),
		FString(TEXT("item:water_bottle")));
	bPassed &= TestEqual(
		TEXT("DefinitionId converts to the matching PrimaryAssetId"),
		DefinitionId.ToPrimaryAssetId().ToString(),
		FString(TEXT("item:water_bottle")));

	FBSDefinitionId Duplicate;
	bPassed &= TestTrue(
		TEXT("The same canonical DefinitionId parses a second time"),
		FBSDefinitionId::TryParse(TEXT("item:water_bottle"), Duplicate));
	bPassed &= TestTrue(TEXT("Equal DefinitionIds compare equal"), DefinitionId == Duplicate);
	bPassed &= TestEqual(
		TEXT("Equal DefinitionIds produce the same hash"),
		GetTypeHash(DefinitionId),
		GetTypeHash(Duplicate));

	TSet<FBSDefinitionId> UniqueDefinitions;
	UniqueDefinitions.Add(DefinitionId);
	UniqueDefinitions.Add(Duplicate);
	bPassed &= TestEqual(
		TEXT("Duplicate DefinitionIds occupy one set entry"),
		UniqueDefinitions.Num(),
		1);

	FBSDefinitionId Different;
	bPassed &= TestTrue(
		TEXT("A different canonical DefinitionId parses"),
		FBSDefinitionId::TryParse(TEXT("vehicle:budget_compact"), Different));
	bPassed &= TestTrue(TEXT("Different DefinitionIds remain distinct"), DefinitionId != Different);

	TArray<uint8> SerializedBytes;
	FMemoryWriter Writer(SerializedBytes);
	Writer << DefinitionId;
	Writer.Close();
	bPassed &= TestFalse(TEXT("DefinitionId archive save has no error"), Writer.IsError());

	FBSDefinitionId Loaded;
	FMemoryReader Reader(SerializedBytes);
	Reader << Loaded;
	Reader.Close();
	bPassed &= TestFalse(TEXT("DefinitionId archive load has no error"), Reader.IsError());
	bPassed &= TestTrue(TEXT("DefinitionId archive round-trip preserves identity"), Loaded == DefinitionId);

	TArray<uint8> InvalidSerializedBytes;
	FString InvalidSerializedText(TEXT("Item:WaterBottle"));
	FMemoryWriter InvalidWriter(InvalidSerializedBytes);
	InvalidWriter << InvalidSerializedText;
	InvalidWriter.Close();
	FBSDefinitionId InvalidLoaded;
	FMemoryReader InvalidReader(InvalidSerializedBytes);
	InvalidReader << InvalidLoaded;
	InvalidReader.Close();
	bPassed &= TestFalse(TEXT("A noncanonical loaded DefinitionId remains invalid"), InvalidLoaded.IsValid());

	const FString OverlongSegment = FString::ChrN(FBSDefinitionId::MaxSegmentLength + 1, TEXT('a'));
	const TArray<FString> InvalidValues = {
		TEXT(""),
		TEXT("item"),
		TEXT(":water_bottle"),
		TEXT("item:"),
		TEXT("item:water:bottle"),
		TEXT("Item:water_bottle"),
		TEXT("item:WaterBottle"),
		TEXT("item:water bottle"),
		TEXT("item:water-bottle"),
		TEXT("1item:water_bottle"),
		FString::Printf(TEXT("item:%s"), *OverlongSegment),
	};

	for (const FString& InvalidValue : InvalidValues)
	{
		FBSDefinitionId OutputBeforeFailure;
		bPassed &= FBSDefinitionId::TryParse(TEXT("item:valid"), OutputBeforeFailure);
		bPassed &= TestFalse(
			*FString::Printf(TEXT("Invalid DefinitionId is rejected: '%s'"), *InvalidValue),
			FBSDefinitionId::TryParse(InvalidValue, OutputBeforeFailure));
		bPassed &= TestFalse(TEXT("A failed DefinitionId parse clears the output"), OutputBeforeFailure.IsValid());
	}

	return bPassed;
}

IMPLEMENT_SIMPLE_AUTOMATION_TEST(
	FBrokenStreetsInstanceIdTest,
	"BrokenStreets.Core.Identity.InstanceId",
	EAutomationTestFlags::EditorContext | EAutomationTestFlags::EngineFilter)

bool FBrokenStreetsInstanceIdTest::RunTest(const FString& Parameters)
{
	bool bPassed = true;
	FBSInstanceId InstanceId;
	const FString CanonicalGuid(TEXT("0f8fad5b-d9cb-469f-a165-70867728950e"));

	bPassed &= TestFalse(TEXT("The default InstanceId is invalid"), InstanceId.IsValid());
	bPassed &= TestTrue(
		TEXT("Canonical InstanceId text parses"),
		FBSInstanceId::TryParse(CanonicalGuid, InstanceId));
	bPassed &= TestTrue(TEXT("A parsed InstanceId is valid"), InstanceId.IsValid());
	bPassed &= TestEqual(TEXT("InstanceId preserves canonical text"), InstanceId.ToString(), CanonicalGuid);

	FBSInstanceId Duplicate;
	bPassed &= TestTrue(
		TEXT("The same canonical InstanceId parses a second time"),
		FBSInstanceId::TryParse(CanonicalGuid, Duplicate));
	bPassed &= TestTrue(TEXT("Equal InstanceIds compare equal"), InstanceId == Duplicate);
	bPassed &= TestEqual(
		TEXT("Equal InstanceIds produce the same hash"),
		GetTypeHash(InstanceId),
		GetTypeHash(Duplicate));

	TSet<FBSInstanceId> UniqueInstances;
	UniqueInstances.Add(InstanceId);
	UniqueInstances.Add(Duplicate);
	bPassed &= TestEqual(TEXT("Duplicate InstanceIds occupy one set entry"), UniqueInstances.Num(), 1);

	const FBSInstanceId GeneratedA = FBSInstanceId::Create();
	const FBSInstanceId GeneratedB = FBSInstanceId::Create();
	bPassed &= TestTrue(TEXT("A generated InstanceId is valid"), GeneratedA.IsValid());
	bPassed &= TestTrue(TEXT("A second generated InstanceId is valid"), GeneratedB.IsValid());
	bPassed &= TestTrue(TEXT("Two generated InstanceIds are distinct"), GeneratedA != GeneratedB);

	FBSInstanceId ParsedGenerated;
	bPassed &= TestTrue(
		TEXT("Generated InstanceId canonical text parses"),
		FBSInstanceId::TryParse(GeneratedA.ToString(), ParsedGenerated));
	bPassed &= TestTrue(TEXT("Generated InstanceId text round-trip preserves identity"), ParsedGenerated == GeneratedA);

	TArray<uint8> SerializedBytes;
	FMemoryWriter Writer(SerializedBytes);
	FBSInstanceId WritableGenerated = GeneratedA;
	Writer << WritableGenerated;
	Writer.Close();
	bPassed &= TestFalse(TEXT("InstanceId archive save has no error"), Writer.IsError());

	FBSInstanceId Loaded;
	FMemoryReader Reader(SerializedBytes);
	Reader << Loaded;
	Reader.Close();
	bPassed &= TestFalse(TEXT("InstanceId archive load has no error"), Reader.IsError());
	bPassed &= TestTrue(TEXT("InstanceId archive round-trip preserves identity"), Loaded == GeneratedA);

	TArray<uint8> ZeroSerializedBytes;
	FGuid ZeroGuid;
	FMemoryWriter ZeroWriter(ZeroSerializedBytes);
	ZeroWriter << ZeroGuid;
	ZeroWriter.Close();
	FBSInstanceId ZeroLoaded;
	FMemoryReader ZeroReader(ZeroSerializedBytes);
	ZeroReader << ZeroLoaded;
	ZeroReader.Close();
	bPassed &= TestFalse(TEXT("A loaded zero GUID remains an invalid InstanceId"), ZeroLoaded.IsValid());

	const TArray<FString> InvalidValues = {
		TEXT(""),
		TEXT("00000000-0000-0000-0000-000000000000"),
		TEXT("0F8FAD5B-D9CB-469F-A165-70867728950E"),
		TEXT("0f8fad5bd9cb469fa16570867728950e"),
		TEXT("{0f8fad5b-d9cb-469f-a165-70867728950e}"),
		TEXT("not-a-guid"),
	};

	for (const FString& InvalidValue : InvalidValues)
	{
		FBSInstanceId OutputBeforeFailure = InstanceId;
		bPassed &= TestFalse(
			*FString::Printf(TEXT("Invalid InstanceId is rejected: '%s'"), *InvalidValue),
			FBSInstanceId::TryParse(InvalidValue, OutputBeforeFailure));
		bPassed &= TestFalse(TEXT("A failed InstanceId parse clears the output"), OutputBeforeFailure.IsValid());
	}

	return bPassed;
}

IMPLEMENT_SIMPLE_AUTOMATION_TEST(
	FBrokenStreetsGameplayTagsPolicyTest,
	"BrokenStreets.Core.Tags.Policy",
	EAutomationTestFlags::EditorContext | EAutomationTestFlags::EngineFilter)

bool FBrokenStreetsGameplayTagsPolicyTest::RunTest(const FString& Parameters)
{
	bool bPassed = true;
	const FGameplayTag ProjectRoot = BSGameplayTags::ProjectRoot.GetTag();

	bPassed &= TestTrue(TEXT("The native Broken Streets Gameplay Tag root is valid"), ProjectRoot.IsValid());
	bPassed &= TestEqual(
		TEXT("The native Gameplay Tag root has the canonical name"),
		ProjectRoot.GetTagName(),
		FName(TEXT("BS")));

	const UGameplayTagsSettings* Settings = GetDefault<UGameplayTagsSettings>();
	bPassed &= TestNotNull(TEXT("Gameplay Tags settings are available"), Settings);
	if (Settings != nullptr)
	{
		bPassed &= TestTrue(TEXT("Gameplay Tags import from config is enabled"), Settings->ImportTagsFromConfig);
		bPassed &= TestTrue(TEXT("Invalid Gameplay Tag warnings are enabled"), Settings->WarnOnInvalidTags);
		bPassed &= TestFalse(TEXT("Gameplay Tag fast replication is not enabled without evidence"), Settings->FastReplication);
		bPassed &= TestFalse(TEXT("Gameplay Tag dynamic replication is not enabled without Iris"), Settings->bDynamicReplication);
		bPassed &= TestFalse(TEXT("Gameplay Tags cannot unload during game runtime"), Settings->AllowGameTagUnloading);
	}

	return bPassed;
}

#endif // WITH_DEV_AUTOMATION_TESTS
