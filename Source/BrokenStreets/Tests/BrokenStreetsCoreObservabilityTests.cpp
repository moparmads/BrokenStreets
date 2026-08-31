// Copyright Madalin Gavrila. All Rights Reserved.

#if WITH_DEV_AUTOMATION_TESTS

#include "Core/FeatureFlags/BSFeatureFlags.h"
#include "Core/Identity/BSIdentifiers.h"
#include "Core/Observability/BSLogCategories.h"
#include "Core/Observability/BSLogContext.h"
#include "Misc/AutomationTest.h"
#include "Misc/ConfigCacheIni.h"

IMPLEMENT_SIMPLE_AUTOMATION_TEST(
	FBrokenStreetsLogContextTest,
	"BrokenStreets.Core.Observability.Context",
	EAutomationTestFlags::EditorContext | EAutomationTestFlags::EngineFilter)

bool FBrokenStreetsLogContextTest::RunTest(const FString& Parameters)
{
	bool bPassed = true;
	FBSLogContext Context;

	bPassed &= TestFalse(TEXT("The default log context is invalid"), Context.IsValid());
	bPassed &= TestTrue(TEXT("An invalid context formats as empty text"), Context.ToLogString().IsEmpty());
	bPassed &= TestTrue(
		TEXT("A canonical operation creates a log context"),
		FBSLogContext::TryCreate(TEXT("load_definition"), Context));
	bPassed &= TestTrue(TEXT("The created log context is valid"), Context.IsValid());
	bPassed &= TestEqual(
		TEXT("The operation-only context has deterministic formatting"),
		Context.ToLogString(),
		FString(TEXT("operation=load_definition")));

	FBSDefinitionId DefinitionId;
	FBSInstanceId InstanceId;
	bPassed &= FBSDefinitionId::TryParse(TEXT("item:water_bottle"), DefinitionId);
	bPassed &= FBSInstanceId::TryParse(TEXT("0f8fad5b-d9cb-469f-a165-70867728950e"), InstanceId);
	bPassed &= TestTrue(TEXT("A valid DefinitionId can be assigned"), Context.TrySetDefinitionId(DefinitionId));
	bPassed &= TestTrue(TEXT("A valid InstanceId can be assigned"), Context.TrySetInstanceId(InstanceId));
	bPassed &= TestTrue(TEXT("The context reports its DefinitionId"), Context.HasDefinitionId());
	bPassed &= TestTrue(TEXT("The context reports its InstanceId"), Context.HasInstanceId());
	bPassed &= TestEqual(
		TEXT("Structured fields use the fixed deterministic order"),
		Context.ToLogString(),
		FString(TEXT("operation=load_definition definition_id=item:water_bottle instance_id=0f8fad5b-d9cb-469f-a165-70867728950e")));

	bPassed &= TestFalse(
		TEXT("An invalid DefinitionId assignment is rejected"),
		Context.TrySetDefinitionId(FBSDefinitionId()));
	bPassed &= TestFalse(TEXT("A rejected DefinitionId leaves no stale field"), Context.HasDefinitionId());
	bPassed &= TestFalse(
		TEXT("An invalid InstanceId assignment is rejected"),
		Context.TrySetInstanceId(FBSInstanceId()));
	bPassed &= TestFalse(TEXT("A rejected InstanceId leaves no stale field"), Context.HasInstanceId());
	bPassed &= TestEqual(
		TEXT("Cleared optional identifiers disappear from formatting"),
		Context.ToLogString(),
		FString(TEXT("operation=load_definition")));

	const FString MaxLengthOperation = FString(TEXT("a"))
		+ FString::ChrN(FBSLogContext::MaxOperationLength - 1, TEXT('1'));
	bPassed &= TestTrue(
		TEXT("A maximum-length canonical operation is accepted"),
		FBSLogContext::TryCreate(MaxLengthOperation, Context));

	const FString OverlongOperation = FString(TEXT("a"))
		+ FString::ChrN(FBSLogContext::MaxOperationLength, TEXT('1'));
	const TArray<FString> InvalidOperations = {
		TEXT(""),
		TEXT("LoadDefinition"),
		TEXT("1load_definition"),
		TEXT("load-definition"),
		TEXT("load definition"),
		TEXT("load\ndefinition"),
		TEXT("load.definition"),
		OverlongOperation,
	};

	for (const FString& InvalidOperation : InvalidOperations)
	{
		bPassed &= FBSLogContext::TryCreate(TEXT("valid_operation"), Context);
		bPassed &= TestFalse(
			*FString::Printf(TEXT("Invalid operation is rejected: '%s'"), *InvalidOperation.ReplaceCharWithEscapedChar()),
			FBSLogContext::TryCreate(InvalidOperation, Context));
		bPassed &= TestFalse(TEXT("A failed create clears the output context"), Context.IsValid());
		bPassed &= TestTrue(TEXT("A cleared output context formats as empty text"), Context.ToLogString().IsEmpty());
	}

	return bPassed;
}

IMPLEMENT_SIMPLE_AUTOMATION_TEST(
	FBrokenStreetsLogCategoriesTest,
	"BrokenStreets.Core.Observability.Categories",
	EAutomationTestFlags::EditorContext | EAutomationTestFlags::EngineFilter)

bool FBrokenStreetsLogCategoriesTest::RunTest(const FString& Parameters)
{
	bool bPassed = true;
	bPassed &= TestEqual(
		TEXT("The project lifecycle category has its canonical name"),
		LogBrokenStreets.GetCategoryName().ToString(),
		FString(TEXT("LogBrokenStreets")));
	bPassed &= TestEqual(
		TEXT("The Core category has its canonical name"),
		LogBSCore.GetCategoryName().ToString(),
		FString(TEXT("LogBSCore")));
	bPassed &= TestTrue(
		TEXT("The two owned categories remain distinct"),
		LogBrokenStreets.GetCategoryName().ToString() != LogBSCore.GetCategoryName().ToString());
	bPassed &= TestEqual(
		TEXT("The project category compiles all standard verbosity levels"),
		LogBrokenStreets.GetCompileTimeVerbosity(),
		ELogVerbosity::All);
	bPassed &= TestEqual(
		TEXT("The Core category compiles all standard verbosity levels"),
		LogBSCore.GetCompileTimeVerbosity(),
		ELogVerbosity::All);

	return bPassed;
}

IMPLEMENT_SIMPLE_AUTOMATION_TEST(
	FBrokenStreetsFeatureFlagsPolicyTest,
	"BrokenStreets.Core.FeatureFlags.Policy",
	EAutomationTestFlags::EditorContext | EAutomationTestFlags::EngineFilter)

bool FBrokenStreetsFeatureFlagsPolicyTest::RunTest(const FString& Parameters)
{
	bool bPassed = true;
	const EBSFeatureFlag DiagnosticFlag = EBSFeatureFlag::CoreVerboseDiagnostics;
	const EBSFeatureFlag UnknownFlag = static_cast<EBSFeatureFlag>(255);

	bPassed &= TestEqual(
		TEXT("The diagnostic flag has a stable log name"),
		FString(FBSFeatureFlags::GetName(DiagnosticFlag)),
		FString(TEXT("core_verbose_diagnostics")));
	bPassed &= TestEqual(
		TEXT("The diagnostic flag has a stable config key"),
		FString(FBSFeatureFlags::GetConfigKey(DiagnosticFlag)),
		FString(TEXT("CoreVerboseDiagnostics")));
	bPassed &= TestNull(TEXT("An unknown flag has no name"), FBSFeatureFlags::GetName(UnknownFlag));
	bPassed &= TestNull(TEXT("An unknown flag has no config key"), FBSFeatureFlags::GetConfigKey(UnknownFlag));
	bPassed &= TestFalse(TEXT("An unknown flag fails closed"), FBSFeatureFlags::IsEnabled(UnknownFlag));

	bool bParsedValue = false;
	bPassed &= TestTrue(
		TEXT("Canonical True parses"),
		FBSFeatureFlags::TryParseConfigValue(TEXT("True"), bParsedValue));
	bPassed &= TestTrue(TEXT("Canonical True resolves enabled"), bParsedValue);
	bPassed &= TestTrue(
		TEXT("Canonical False parses"),
		FBSFeatureFlags::TryParseConfigValue(TEXT("False"), bParsedValue));
	bPassed &= TestFalse(TEXT("Canonical False resolves disabled"), bParsedValue);

	const TArray<FString> InvalidValues = {
		TEXT(""),
		TEXT("true"),
		TEXT("false"),
		TEXT("1"),
		TEXT("Enabled"),
		TEXT("True\nFalse"),
	};
	for (const FString& InvalidValue : InvalidValues)
	{
		bParsedValue = true;
		bPassed &= TestFalse(
			*FString::Printf(TEXT("Malformed feature-flag value is rejected: '%s'"), *InvalidValue.ReplaceCharWithEscapedChar()),
			FBSFeatureFlags::TryParseConfigValue(InvalidValue, bParsedValue));
		bPassed &= TestFalse(TEXT("A failed feature-flag parse clears its output"), bParsedValue);
	}

	FString DefaultValue;
	bPassed &= TestNotNull(TEXT("The Unreal config cache is available"), GConfig);
	if (GConfig != nullptr)
	{
		bPassed &= TestTrue(
			TEXT("The diagnostic flag has a project-owned default"),
			GConfig->GetString(
				TEXT("BrokenStreets.FeatureFlags"),
				TEXT("CoreVerboseDiagnostics"),
				DefaultValue,
				GGameIni));
		bPassed &= TestEqual(
			TEXT("The diagnostic flag defaults to False"),
			DefaultValue,
			FString(TEXT("False")));
		bPassed &= TestFalse(
			TEXT("The default diagnostic flag resolves disabled"),
			FBSFeatureFlags::IsEnabled(DiagnosticFlag));

		GConfig->SetString(
			TEXT("BrokenStreets.FeatureFlags"),
			TEXT("CoreVerboseDiagnostics"),
			TEXT("True"),
			GGameIni);
		bPassed &= TestTrue(
			TEXT("A canonical True config override resolves enabled"),
			FBSFeatureFlags::IsEnabled(DiagnosticFlag));

		GConfig->SetString(
			TEXT("BrokenStreets.FeatureFlags"),
			TEXT("CoreVerboseDiagnostics"),
			TEXT("False"),
			GGameIni);
		bPassed &= TestFalse(
			TEXT("A canonical False config override resolves disabled"),
			FBSFeatureFlags::IsEnabled(DiagnosticFlag));

		GConfig->SetString(
			TEXT("BrokenStreets.FeatureFlags"),
			TEXT("CoreVerboseDiagnostics"),
			*DefaultValue,
			GGameIni);
	}

	return bPassed;
}

#endif // WITH_DEV_AUTOMATION_TESTS
