// Copyright Madalin Gavrila. All Rights Reserved.

#if WITH_DEV_AUTOMATION_TESTS

#include "Core/Compatibility/BSCompatibility.h"
#include "Misc/AutomationTest.h"
#include "Misc/ConfigCacheIni.h"

IMPLEMENT_SIMPLE_AUTOMATION_TEST(
	FBrokenStreetsCompatibilityPolicyTest,
	"BrokenStreets.Core.Compatibility.Policy",
	EAutomationTestFlags::EditorContext | EAutomationTestFlags::EngineFilter)

bool FBrokenStreetsCompatibilityPolicyTest::RunTest(const FString& Parameters)
{
	bool bPassed = true;

	uint32 ParsedVersion = 99;
	bPassed &= TestTrue(TEXT("The minimum canonical version parses"), FBSCompatibility::TryParseVersion(TEXT("1"), ParsedVersion));
	bPassed &= TestEqual(TEXT("The minimum parsed value is exact"), ParsedVersion, 1u);
	bPassed &= TestTrue(
		TEXT("The maximum uint32 version parses"),
		FBSCompatibility::TryParseVersion(TEXT("4294967295"), ParsedVersion));
	bPassed &= TestEqual(TEXT("The maximum parsed value is exact"), ParsedVersion, MAX_uint32);

	const TArray<FString> InvalidVersionTexts = {
		TEXT(""),
		TEXT("0"),
		TEXT("01"),
		TEXT("+1"),
		TEXT("-1"),
		TEXT(" 1"),
		TEXT("1 "),
		TEXT("1.0"),
		TEXT("1\n2"),
		TEXT("4294967296"),
		TEXT("version1"),
	};
	for (const FString& InvalidText : InvalidVersionTexts)
	{
		ParsedVersion = 99;
		bPassed &= TestFalse(
			*FString::Printf(TEXT("Noncanonical version is rejected: '%s'"), *InvalidText.ReplaceCharWithEscapedChar()),
			FBSCompatibility::TryParseVersion(InvalidText, ParsedVersion));
		bPassed &= TestEqual(TEXT("A failed version parse clears the output"), ParsedVersion, 0u);
	}

	FBSCompatibilitySignature Signature;
	bPassed &= TestFalse(TEXT("The default signature is invalid"), Signature.IsValid());
	bPassed &= TestTrue(TEXT("A non-zero signature is accepted"), FBSCompatibilitySignature::TryCreate(2, 3, 4, Signature));
	bPassed &= TestTrue(TEXT("The created signature is valid"), Signature.IsValid());
	bPassed &= TestEqual(TEXT("The signature retains its build version"), Signature.GetBuildCompatibilityVersion(), 2u);
	bPassed &= TestEqual(TEXT("The signature retains its content version"), Signature.GetContentCompatibilityVersion(), 3u);
	bPassed &= TestEqual(TEXT("The signature retains its save schema"), Signature.GetSaveSchemaVersion(), 4u);
	bPassed &= TestFalse(TEXT("A zero signature field is rejected"), FBSCompatibilitySignature::TryCreate(2, 0, 4, Signature));
	bPassed &= TestFalse(TEXT("A rejected signature clears prior state"), Signature.IsValid());

	FBSCompatibilityPolicy Policy;
	bPassed &= TestFalse(TEXT("The default policy is invalid"), Policy.IsValid());
	bPassed &= TestTrue(TEXT("A bounded save range is accepted"), FBSCompatibilityPolicy::TryCreate(7, 8, 5, 2, Policy));
	bPassed &= TestTrue(TEXT("The created policy is valid"), Policy.IsValid());
	bPassed &= TestEqual(TEXT("The policy retains its build version"), Policy.GetBuildCompatibilityVersion(), 7u);
	bPassed &= TestEqual(TEXT("The policy retains its content version"), Policy.GetContentCompatibilityVersion(), 8u);
	bPassed &= TestEqual(TEXT("The policy retains its current save schema"), Policy.GetCurrentSaveSchemaVersion(), 5u);
	bPassed &= TestEqual(TEXT("The policy retains its minimum readable schema"), Policy.GetMinimumReadableSaveSchemaVersion(), 2u);

	const FBSCompatibilitySignature CurrentSignature = Policy.GetCurrentSignature();
	bPassed &= TestTrue(TEXT("A valid policy produces a valid current signature"), CurrentSignature.IsValid());
	bPassed &= TestEqual(TEXT("The current signature uses the policy build"), CurrentSignature.GetBuildCompatibilityVersion(), 7u);
	bPassed &= TestEqual(TEXT("The current signature uses the policy content"), CurrentSignature.GetContentCompatibilityVersion(), 8u);
	bPassed &= TestEqual(TEXT("The current signature uses the current schema"), CurrentSignature.GetSaveSchemaVersion(), 5u);

	bPassed &= TestFalse(TEXT("An inverted save range is rejected"), FBSCompatibilityPolicy::TryCreate(7, 8, 2, 3, Policy));
	bPassed &= TestFalse(TEXT("A rejected policy clears prior state"), Policy.IsValid());
	bPassed &= TestFalse(TEXT("An invalid policy produces an invalid current signature"), Policy.GetCurrentSignature().IsValid());

	FBSCompatibilityPolicy ProjectPolicy;
	bPassed &= TestTrue(TEXT("The project-owned compatibility policy loads"), FBSCompatibility::TryLoadCurrentPolicy(ProjectPolicy));
	bPassed &= TestEqual(TEXT("The project build compatibility version defaults to 1"), ProjectPolicy.GetBuildCompatibilityVersion(), 1u);
	bPassed &= TestEqual(TEXT("The project content compatibility version defaults to 1"), ProjectPolicy.GetContentCompatibilityVersion(), 1u);
	bPassed &= TestEqual(TEXT("The project current save schema defaults to 1"), ProjectPolicy.GetCurrentSaveSchemaVersion(), 1u);
	bPassed &= TestEqual(TEXT("The project minimum readable save schema defaults to 1"), ProjectPolicy.GetMinimumReadableSaveSchemaVersion(), 1u);

	bPassed &= TestNotNull(TEXT("The Unreal config cache is available"), GConfig);
	if (GConfig != nullptr)
	{
		FString OriginalContentVersion;
		const bool bReadOriginal = GConfig->GetString(
			TEXT("BrokenStreets.Compatibility"),
			TEXT("ContentCompatibilityVersion"),
			OriginalContentVersion,
			GGameIni);
		bPassed &= TestTrue(
			TEXT("The source-controlled content version can be read for restoration"),
			bReadOriginal);

		if (bReadOriginal)
		{
			GConfig->SetString(
				TEXT("BrokenStreets.Compatibility"),
				TEXT("ContentCompatibilityVersion"),
				TEXT("01"),
				GGameIni);
			bPassed &= TestTrue(
				TEXT("The malformed-load fixture begins with a valid output policy"),
				FBSCompatibilityPolicy::TryCreate(9, 9, 9, 9, ProjectPolicy));
			bPassed &= TestFalse(
				TEXT("Malformed project configuration fails closed"),
				FBSCompatibility::TryLoadCurrentPolicy(ProjectPolicy));
			bPassed &= TestFalse(TEXT("A failed configuration load clears stale policy state"), ProjectPolicy.IsValid());

			GConfig->SetString(
				TEXT("BrokenStreets.Compatibility"),
				TEXT("ContentCompatibilityVersion"),
				*OriginalContentVersion,
				GGameIni);
		}
	}

	return bPassed;
}

IMPLEMENT_SIMPLE_AUTOMATION_TEST(
	FBrokenStreetsCompatibilityEvaluationTest,
	"BrokenStreets.Core.Compatibility.Evaluation",
	EAutomationTestFlags::EditorContext | EAutomationTestFlags::EngineFilter)

bool FBrokenStreetsCompatibilityEvaluationTest::RunTest(const FString& Parameters)
{
	bool bPassed = true;

	FBSCompatibilityPolicy Policy;
	bPassed &= TestTrue(
		TEXT("The evaluation policy fixture is valid"),
		FBSCompatibilityPolicy::TryCreate(3, 4, 5, 2, Policy));

	FBSCompatibilitySignature Signature;
	bPassed &= TestTrue(
		TEXT("The current-signature fixture is valid"),
		FBSCompatibilitySignature::TryCreate(3, 4, 5, Signature));
	bPassed &= TestEqual(
		TEXT("The current signature is compatible"),
		FBSCompatibility::Evaluate(Policy, Signature),
		EBSCompatibilityResult::Compatible);

	bPassed &= TestTrue(
		TEXT("The minimum-schema fixture is valid"),
		FBSCompatibilitySignature::TryCreate(3, 4, 2, Signature));
	bPassed &= TestEqual(
		TEXT("The minimum readable schema is inclusive"),
		FBSCompatibility::Evaluate(Policy, Signature),
		EBSCompatibilityResult::Compatible);
	bPassed &= TestTrue(
		TEXT("The inside-range fixture is valid"),
		FBSCompatibilitySignature::TryCreate(3, 4, 3, Signature));
	bPassed &= TestEqual(
		TEXT("A schema inside the readable range is compatible"),
		FBSCompatibility::Evaluate(Policy, Signature),
		EBSCompatibilityResult::Compatible);

	FBSCompatibilityPolicy InvalidPolicy;
	bPassed &= TestEqual(
		TEXT("An invalid local policy fails closed first"),
		FBSCompatibility::Evaluate(InvalidPolicy, FBSCompatibilitySignature()),
		EBSCompatibilityResult::InvalidPolicy);
	bPassed &= TestEqual(
		TEXT("An invalid candidate signature fails closed"),
		FBSCompatibility::Evaluate(Policy, FBSCompatibilitySignature()),
		EBSCompatibilityResult::InvalidSignature);

	bPassed &= TestTrue(
		TEXT("The build-mismatch fixture is valid"),
		FBSCompatibilitySignature::TryCreate(9, 8, 1, Signature));
	bPassed &= TestEqual(
		TEXT("Build mismatch has deterministic precedence"),
		FBSCompatibility::Evaluate(Policy, Signature),
		EBSCompatibilityResult::BuildVersionMismatch);
	bPassed &= TestTrue(
		TEXT("The content-mismatch fixture is valid"),
		FBSCompatibilitySignature::TryCreate(3, 8, 1, Signature));
	bPassed &= TestEqual(
		TEXT("Content mismatch precedes save mismatch"),
		FBSCompatibility::Evaluate(Policy, Signature),
		EBSCompatibilityResult::ContentVersionMismatch);
	bPassed &= TestTrue(
		TEXT("The too-old-schema fixture is valid"),
		FBSCompatibilitySignature::TryCreate(3, 4, 1, Signature));
	bPassed &= TestEqual(
		TEXT("A schema below the readable range is rejected"),
		FBSCompatibility::Evaluate(Policy, Signature),
		EBSCompatibilityResult::SaveSchemaTooOld);
	bPassed &= TestTrue(
		TEXT("The too-new-schema fixture is valid"),
		FBSCompatibilitySignature::TryCreate(3, 4, 6, Signature));
	bPassed &= TestEqual(
		TEXT("A schema above the current version is rejected"),
		FBSCompatibility::Evaluate(Policy, Signature),
		EBSCompatibilityResult::SaveSchemaTooNew);

	const TArray<TPair<EBSCompatibilityResult, FString>> StableNames = {
		{EBSCompatibilityResult::Compatible, TEXT("compatible")},
		{EBSCompatibilityResult::InvalidPolicy, TEXT("invalid_policy")},
		{EBSCompatibilityResult::InvalidSignature, TEXT("invalid_signature")},
		{EBSCompatibilityResult::BuildVersionMismatch, TEXT("build_version_mismatch")},
		{EBSCompatibilityResult::ContentVersionMismatch, TEXT("content_version_mismatch")},
		{EBSCompatibilityResult::SaveSchemaTooOld, TEXT("save_schema_too_old")},
		{EBSCompatibilityResult::SaveSchemaTooNew, TEXT("save_schema_too_new")},
	};
	for (const TPair<EBSCompatibilityResult, FString>& Entry : StableNames)
	{
		bPassed &= TestEqual(
			*FString::Printf(TEXT("Result %d has a stable name"), static_cast<int32>(Entry.Key)),
			FString(FBSCompatibility::GetStableName(Entry.Key)),
			Entry.Value);
	}
	bPassed &= TestEqual(
		TEXT("An unknown result has a bounded diagnostic name"),
		FString(FBSCompatibility::GetStableName(static_cast<EBSCompatibilityResult>(255))),
		FString(TEXT("unknown")));

	return bPassed;
}

#endif // WITH_DEV_AUTOMATION_TESTS
