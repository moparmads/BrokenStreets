// Copyright Madalin Gavrila. All Rights Reserved.

#if WITH_DEV_AUTOMATION_TESTS

#include "Core/Commands/BSCommandEnvelope.h"
#include "Core/Results/BSResult.h"
#include "Misc/AutomationTest.h"

#include <type_traits>

static_assert(!std::is_same_v<FBSCommandId, FBSCorrelationId>);
static_assert(!std::is_constructible_v<FBSCommandId, FBSCorrelationId>);
static_assert(!std::is_constructible_v<FBSCorrelationId, FBSCommandId>);
static_assert(!std::is_convertible_v<FGuid, FBSCommandId>);
static_assert(!std::is_convertible_v<FGuid, FBSCorrelationId>);

IMPLEMENT_SIMPLE_AUTOMATION_TEST(
	FBrokenStreetsCommandEnvelopeTest,
	"BrokenStreets.Core.Commands.Envelope",
	EAutomationTestFlags::EditorContext | EAutomationTestFlags::EngineFilter)

bool FBrokenStreetsCommandEnvelopeTest::RunTest(const FString& Parameters)
{
	bool bPassed = true;
	const FString CommandText(TEXT("0f8fad5b-d9cb-469f-a165-70867728950e"));
	const FString CorrelationText(TEXT("7c9e6679-7425-40de-944b-e07fc1f90ae7"));

	FBSCommandId CommandId;
	FBSCorrelationId CorrelationId;
	bPassed &= TestFalse(TEXT("The default CommandId is invalid"), CommandId.IsValid());
	bPassed &= TestFalse(TEXT("The default CorrelationId is invalid"), CorrelationId.IsValid());
	bPassed &= TestTrue(TEXT("Canonical CommandId text parses"), FBSCommandId::TryParse(CommandText, CommandId));
	bPassed &= TestTrue(TEXT("Canonical CorrelationId text parses"), FBSCorrelationId::TryParse(CorrelationText, CorrelationId));
	bPassed &= TestEqual(TEXT("CommandId preserves canonical text"), CommandId.ToString(), CommandText);
	bPassed &= TestEqual(TEXT("CorrelationId preserves canonical text"), CorrelationId.ToString(), CorrelationText);

	const FBSCommandId GeneratedCommandA = FBSCommandId::Create();
	const FBSCommandId GeneratedCommandB = FBSCommandId::Create();
	const FBSCorrelationId GeneratedCorrelationA = FBSCorrelationId::Create();
	const FBSCorrelationId GeneratedCorrelationB = FBSCorrelationId::Create();
	bPassed &= TestTrue(TEXT("A generated CommandId is valid"), GeneratedCommandA.IsValid());
	bPassed &= TestTrue(TEXT("A second generated CommandId is valid"), GeneratedCommandB.IsValid());
	bPassed &= TestTrue(TEXT("Generated CommandIds are distinct"), GeneratedCommandA != GeneratedCommandB);
	bPassed &= TestTrue(TEXT("A generated CorrelationId is valid"), GeneratedCorrelationA.IsValid());
	bPassed &= TestTrue(TEXT("A second generated CorrelationId is valid"), GeneratedCorrelationB.IsValid());
	bPassed &= TestTrue(
		TEXT("Generated CorrelationIds are distinct"),
		GeneratedCorrelationA != GeneratedCorrelationB);

	FBSCommandEnvelope Envelope;
	bPassed &= TestFalse(TEXT("The default command envelope is invalid"), Envelope.IsValid());
	bPassed &= TestTrue(
		TEXT("Valid identifiers create an envelope"),
		FBSCommandEnvelope::TryCreate(CommandId, CorrelationId, Envelope));
	bPassed &= TestTrue(TEXT("The created envelope is valid"), Envelope.IsValid());
	bPassed &= TestTrue(TEXT("The envelope retains the CommandId"), Envelope.GetCommandId() == CommandId);
	bPassed &= TestTrue(TEXT("The envelope retains the CorrelationId"), Envelope.GetCorrelationId() == CorrelationId);

	bPassed &= TestFalse(
		TEXT("An invalid CommandId is rejected"),
		FBSCommandEnvelope::TryCreate(FBSCommandId(), CorrelationId, Envelope));
	bPassed &= TestFalse(TEXT("A rejected envelope clears prior state"), Envelope.IsValid());
	bPassed &= TestFalse(
		TEXT("An invalid CorrelationId is rejected"),
		FBSCommandEnvelope::TryCreate(CommandId, FBSCorrelationId(), Envelope));
	bPassed &= TestFalse(TEXT("A second rejected envelope remains cleared"), Envelope.IsValid());

	const FBSCommandEnvelope Root = FBSCommandEnvelope::CreateRoot();
	bPassed &= TestTrue(TEXT("A generated root envelope is valid"), Root.IsValid());
	bPassed &= TestTrue(
		TEXT("Root command and correlation identifiers are distinct values"),
		Root.GetCommandId().GetGuid() != Root.GetCorrelationId().GetGuid());

	FBSCommandEnvelope Child;
	bPassed &= TestTrue(TEXT("A valid root creates a child envelope"), FBSCommandEnvelope::TryCreateChild(Root, Child));
	bPassed &= TestTrue(TEXT("The generated child envelope is valid"), Child.IsValid());
	bPassed &= TestTrue(
		TEXT("A child command receives a new CommandId"),
		Child.GetCommandId() != Root.GetCommandId());
	bPassed &= TestTrue(
		TEXT("A child CommandId remains distinct from the inherited CorrelationId"),
		Child.GetCommandId().GetGuid() != Child.GetCorrelationId().GetGuid());
	bPassed &= TestTrue(
		TEXT("A child preserves the root CorrelationId"),
		Child.GetCorrelationId() == Root.GetCorrelationId());

	bPassed &= TestFalse(
		TEXT("An invalid parent cannot create a child"),
		FBSCommandEnvelope::TryCreateChild(FBSCommandEnvelope(), Child));
	bPassed &= TestFalse(TEXT("A rejected child creation clears prior state"), Child.IsValid());

	const TArray<FString> InvalidGuidTexts = {
		TEXT(""),
		TEXT("00000000-0000-0000-0000-000000000000"),
		TEXT("0F8FAD5B-D9CB-469F-A165-70867728950E"),
		TEXT("0f8fad5bd9cb469fa16570867728950e"),
		TEXT("{0f8fad5b-d9cb-469f-a165-70867728950e}"),
		TEXT("not-a-guid"),
	};

	for (const FString& InvalidText : InvalidGuidTexts)
	{
		CommandId = FBSCommandId::Create();
		CorrelationId = FBSCorrelationId::Create();
		bPassed &= TestFalse(
			*FString::Printf(TEXT("Invalid CommandId is rejected: '%s'"), *InvalidText),
			FBSCommandId::TryParse(InvalidText, CommandId));
		bPassed &= TestFalse(TEXT("A failed CommandId parse clears prior state"), CommandId.IsValid());
		bPassed &= TestFalse(
			*FString::Printf(TEXT("Invalid CorrelationId is rejected: '%s'"), *InvalidText),
			FBSCorrelationId::TryParse(InvalidText, CorrelationId));
		bPassed &= TestFalse(TEXT("A failed CorrelationId parse clears prior state"), CorrelationId.IsValid());
	}

	return bPassed;
}

IMPLEMENT_SIMPLE_AUTOMATION_TEST(
	FBrokenStreetsResultPolicyTest,
	"BrokenStreets.Core.Results.Policy",
	EAutomationTestFlags::EditorContext | EAutomationTestFlags::EngineFilter)

bool FBrokenStreetsResultPolicyTest::RunTest(const FString& Parameters)
{
	bool bPassed = true;
	FBSErrorCode ErrorCode;

	bPassed &= TestFalse(TEXT("The default error code is invalid"), ErrorCode.IsValid());
	bPassed &= TestTrue(
		TEXT("A canonical error code parses"),
		FBSErrorCode::TryParse(TEXT("economy.insufficient_funds"), ErrorCode));
	bPassed &= TestTrue(TEXT("A parsed error code is valid"), ErrorCode.IsValid());
	bPassed &= TestEqual(
		TEXT("An error code preserves canonical text"),
		ErrorCode.ToString(),
		FString(TEXT("economy.insufficient_funds")));

	FBSErrorCode Duplicate;
	bPassed &= FBSErrorCode::TryParse(TEXT("economy.insufficient_funds"), Duplicate);
	bPassed &= TestTrue(TEXT("Equal error codes compare equal"), ErrorCode == Duplicate);
	bPassed &= TestEqual(TEXT("Equal error codes produce equal hashes"), GetTypeHash(ErrorCode), GetTypeHash(Duplicate));

	const FString MaxSegment = FString(TEXT("a"))
		+ FString::ChrN(FBSErrorCode::MaxSegmentLength - 1, TEXT('1'));
	bPassed &= TestTrue(
		TEXT("Maximum-length error-code segments are accepted"),
		FBSErrorCode::TryParse(MaxSegment + TEXT(".") + MaxSegment, ErrorCode));

	const FString OverlongSegment = FString(TEXT("a"))
		+ FString::ChrN(FBSErrorCode::MaxSegmentLength, TEXT('1'));
	const TArray<FString> InvalidCodes = {
		TEXT(""),
		TEXT("economy"),
		TEXT(".insufficient_funds"),
		TEXT("economy."),
		TEXT("economy.insufficient.funds"),
		TEXT("Economy.insufficient_funds"),
		TEXT("economy.InsufficientFunds"),
		TEXT("1economy.insufficient_funds"),
		TEXT("economy.1insufficient_funds"),
		TEXT("economy.insufficient-funds"),
		TEXT("economy.insufficient funds"),
		TEXT("economy.insufficient\nfunds"),
		OverlongSegment + TEXT(".reason"),
	};

	for (const FString& InvalidCode : InvalidCodes)
	{
		bPassed &= FBSErrorCode::TryParse(TEXT("core.valid_reason"), ErrorCode);
		bPassed &= TestFalse(
			*FString::Printf(TEXT("Invalid error code is rejected: '%s'"), *InvalidCode.ReplaceCharWithEscapedChar()),
			FBSErrorCode::TryParse(InvalidCode, ErrorCode));
		bPassed &= TestFalse(TEXT("A failed error-code parse clears prior state"), ErrorCode.IsValid());
	}

	FBSResult Result;
	bPassed &= TestFalse(TEXT("The default result is invalid"), Result.IsValid());
	bPassed &= TestEqual(TEXT("The default result status is Invalid"), Result.GetStatus(), EBSResultStatus::Invalid);

	Result = FBSResult::Succeeded();
	bPassed &= TestTrue(TEXT("The success result is valid"), Result.IsValid());
	bPassed &= TestTrue(TEXT("The success result reports succeeded"), Result.IsSucceeded());
	bPassed &= TestFalse(TEXT("The success result has no error code"), Result.GetErrorCode().IsValid());

	bPassed &= FBSErrorCode::TryParse(TEXT("inventory.capacity_exceeded"), ErrorCode);
	bPassed &= TestTrue(TEXT("A valid error creates a rejection"), FBSResult::TryCreateRejected(ErrorCode, Result));
	bPassed &= TestTrue(TEXT("The rejection result is valid"), Result.IsValid());
	bPassed &= TestTrue(TEXT("The rejection result reports rejected"), Result.IsRejected());
	bPassed &= TestTrue(TEXT("The rejection retains its error code"), Result.GetErrorCode() == ErrorCode);

	bPassed &= TestTrue(TEXT("A valid error creates a failure"), FBSResult::TryCreateFailed(ErrorCode, Result));
	bPassed &= TestTrue(TEXT("The failure result is valid"), Result.IsValid());
	bPassed &= TestTrue(TEXT("The failure result reports failed"), Result.IsFailed());
	bPassed &= TestTrue(TEXT("The failure retains its error code"), Result.GetErrorCode() == ErrorCode);

	bPassed &= TestFalse(
		TEXT("An invalid error cannot create a rejection"),
		FBSResult::TryCreateRejected(FBSErrorCode(), Result));
	bPassed &= TestFalse(TEXT("A rejected result construction clears prior state"), Result.IsValid());
	bPassed &= TestEqual(TEXT("A cleared result returns to Invalid"), Result.GetStatus(), EBSResultStatus::Invalid);

	const TArray<TPair<EBSResultStatus, FString>> StableNames = {
		{EBSResultStatus::Invalid, TEXT("invalid")},
		{EBSResultStatus::Succeeded, TEXT("succeeded")},
		{EBSResultStatus::Rejected, TEXT("rejected")},
		{EBSResultStatus::Failed, TEXT("failed")},
	};
	for (const TPair<EBSResultStatus, FString>& Entry : StableNames)
	{
		bPassed &= TestEqual(
			*FString::Printf(TEXT("Result status %d has a stable name"), static_cast<int32>(Entry.Key)),
			FString(FBSResult::GetStableName(Entry.Key)),
			Entry.Value);
	}
	bPassed &= TestEqual(
		TEXT("An unknown result status has a bounded diagnostic name"),
		FString(FBSResult::GetStableName(static_cast<EBSResultStatus>(255))),
		FString(TEXT("unknown")));

	return bPassed;
}

#endif // WITH_DEV_AUTOMATION_TESTS
