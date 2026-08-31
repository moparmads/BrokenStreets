// Copyright Madalin Gavrila. All Rights Reserved.

#if WITH_DEV_AUTOMATION_TESTS

#include "Save/Serialization/BSSaveEnvelope.h"

#include "Misc/AutomationTest.h"
#include "Misc/Crc.h"

namespace
{
constexpr int32 SaveSchemaVersionOffset = 20;
constexpr int32 PayloadSizeOffset = 24;
constexpr int32 ChecksumOffset = 28;

uint32 ReadUInt32LittleEndian(const TArray<uint8>& Bytes, const int32 Offset)
{
	return static_cast<uint32>(Bytes[Offset])
		| (static_cast<uint32>(Bytes[Offset + 1]) << 8)
		| (static_cast<uint32>(Bytes[Offset + 2]) << 16)
		| (static_cast<uint32>(Bytes[Offset + 3]) << 24);
}

void WriteUInt32LittleEndian(TArray<uint8>& Bytes, const int32 Offset, const uint32 Value)
{
	Bytes[Offset] = static_cast<uint8>(Value);
	Bytes[Offset + 1] = static_cast<uint8>(Value >> 8);
	Bytes[Offset + 2] = static_cast<uint8>(Value >> 16);
	Bytes[Offset + 3] = static_cast<uint8>(Value >> 24);
}

void RefreshChecksum(TArray<uint8>& Bytes)
{
	const uint32 PayloadSize = ReadUInt32LittleEndian(Bytes, PayloadSizeOffset);
	uint32 Checksum = FCrc::MemCrc32(Bytes.GetData(), ChecksumOffset);
	if (PayloadSize > 0)
	{
		Checksum = FCrc::MemCrc32(
			Bytes.GetData() + FBSSaveEnvelopeHeader::SerializedSize,
			PayloadSize,
			Checksum);
	}
	WriteUInt32LittleEndian(Bytes, ChecksumOffset, Checksum);
}

bool CreatePolicy(
	const uint32 BuildVersion,
	const uint32 ContentVersion,
	const uint32 CurrentSaveVersion,
	const uint32 MinimumReadableSaveVersion,
	FBSCompatibilityPolicy& OutPolicy)
{
	return FBSCompatibilityPolicy::TryCreate(
		BuildVersion,
		ContentVersion,
		CurrentSaveVersion,
		MinimumReadableSaveVersion,
		OutPolicy);
}
} // namespace

IMPLEMENT_SIMPLE_AUTOMATION_TEST(
	FBrokenStreetsSaveEnvelopeHeaderTest,
	"BrokenStreets.Save.Envelope.Header",
	EAutomationTestFlags::EditorContext | EAutomationTestFlags::EngineFilter)

bool FBrokenStreetsSaveEnvelopeHeaderTest::RunTest(const FString& Parameters)
{
	bool bPassed = true;

	FBSSaveEnvelopeHeader Header;
	bPassed &= TestFalse(TEXT("The default save-envelope header is invalid"), Header.IsValid());

	FBSCompatibilitySignature Signature;
	bPassed &= TestTrue(
		TEXT("The header signature fixture is valid"),
		FBSCompatibilitySignature::TryCreate(2, 3, 4, Signature));
	bPassed &= TestTrue(
		TEXT("A valid save-envelope header can be created"),
		FBSSaveEnvelopeHeader::TryCreate(Signature, 5, 0x12345678, Header));
	bPassed &= TestTrue(TEXT("The created save-envelope header is valid"), Header.IsValid());
	bPassed &= TestEqual(
		TEXT("The envelope format version is fixed"),
		Header.GetEnvelopeFormatVersion(),
		FBSSaveEnvelopeHeader::EnvelopeFormatVersion);
	bPassed &= TestEqual(
		TEXT("The serialized header size is fixed"),
		Header.GetSerializedHeaderSize(),
		FBSSaveEnvelopeHeader::SerializedSize);
	bPassed &= TestEqual(
		TEXT("The header retains the build compatibility version"),
		Header.GetCompatibilitySignature().GetBuildCompatibilityVersion(),
		2u);
	bPassed &= TestEqual(
		TEXT("The header retains the content compatibility version"),
		Header.GetCompatibilitySignature().GetContentCompatibilityVersion(),
		3u);
	bPassed &= TestEqual(
		TEXT("The header retains the save schema version"),
		Header.GetCompatibilitySignature().GetSaveSchemaVersion(),
		4u);
	bPassed &= TestEqual(TEXT("The header retains the payload size"), Header.GetPayloadSize(), 5u);
	bPassed &= TestEqual(TEXT("The header retains the checksum"), Header.GetEnvelopeChecksum(), 0x12345678u);

	bPassed &= TestFalse(
		TEXT("An invalid signature is rejected and clears prior header state"),
		FBSSaveEnvelopeHeader::TryCreate(FBSCompatibilitySignature(), 5, 7, Header));
	bPassed &= TestFalse(TEXT("The rejected invalid-signature header is cleared"), Header.IsValid());

	bPassed &= TestTrue(
		TEXT("The valid signature fixture can be restored"),
		FBSCompatibilitySignature::TryCreate(2, 3, 4, Signature));
	bPassed &= TestFalse(
		TEXT("A payload above the absolute cap is rejected"),
		FBSSaveEnvelopeHeader::TryCreate(
			Signature,
			FBSSaveEnvelopeHeader::MaxPayloadSize + 1,
			7,
			Header));
	bPassed &= TestFalse(TEXT("The rejected oversized header is cleared"), Header.IsValid());

	const TArray<TPair<EBSSaveEnvelopeResult, FString>> StableNames = {
		{EBSSaveEnvelopeResult::Succeeded, TEXT("succeeded")},
		{EBSSaveEnvelopeResult::InvalidPolicy, TEXT("invalid_policy")},
		{EBSSaveEnvelopeResult::PayloadTooLarge, TEXT("payload_too_large")},
		{EBSSaveEnvelopeResult::HeaderTruncated, TEXT("header_truncated")},
		{EBSSaveEnvelopeResult::InvalidMagic, TEXT("invalid_magic")},
		{EBSSaveEnvelopeResult::UnsupportedFormatVersion, TEXT("unsupported_format_version")},
		{EBSSaveEnvelopeResult::InvalidHeaderSize, TEXT("invalid_header_size")},
		{EBSSaveEnvelopeResult::FileSizeMismatch, TEXT("file_size_mismatch")},
		{EBSSaveEnvelopeResult::ChecksumMismatch, TEXT("checksum_mismatch")},
		{EBSSaveEnvelopeResult::InvalidCompatibilitySignature, TEXT("invalid_compatibility_signature")},
		{EBSSaveEnvelopeResult::BuildVersionMismatch, TEXT("build_version_mismatch")},
		{EBSSaveEnvelopeResult::ContentVersionMismatch, TEXT("content_version_mismatch")},
		{EBSSaveEnvelopeResult::SaveSchemaTooOld, TEXT("save_schema_too_old")},
		{EBSSaveEnvelopeResult::SaveSchemaTooNew, TEXT("save_schema_too_new")},
	};
	for (const TPair<EBSSaveEnvelopeResult, FString>& Entry : StableNames)
	{
		bPassed &= TestEqual(
			*FString::Printf(TEXT("Save-envelope result %d has a stable name"), static_cast<int32>(Entry.Key)),
			FString(FBSSaveEnvelope::GetStableName(Entry.Key)),
			Entry.Value);
	}
	bPassed &= TestEqual(
		TEXT("An unknown save-envelope result has a bounded diagnostic name"),
		FString(FBSSaveEnvelope::GetStableName(static_cast<EBSSaveEnvelopeResult>(255))),
		FString(TEXT("unknown")));

	return bPassed;
}

IMPLEMENT_SIMPLE_AUTOMATION_TEST(
	FBrokenStreetsSaveEnvelopeRoundTripGoldenTest,
	"BrokenStreets.Save.Envelope.RoundTripGolden",
	EAutomationTestFlags::EditorContext | EAutomationTestFlags::EngineFilter)

bool FBrokenStreetsSaveEnvelopeRoundTripGoldenTest::RunTest(const FString& Parameters)
{
	bool bPassed = true;

	FBSCompatibilityPolicy Policy;
	bPassed &= TestTrue(TEXT("The golden policy fixture is valid"), CreatePolicy(1, 1, 1, 1, Policy));

	const TArray<uint8> Payload = {0x10, 0x20, 0x30, 0x40};
	TArray<uint8> Serialized;
	bPassed &= TestEqual(
		TEXT("The golden payload serializes"),
		FBSSaveEnvelope::TrySerialize(Policy, Payload, Serialized),
		EBSSaveEnvelopeResult::Succeeded);

	const TArray<uint8> GoldenBytes = {
		0x42, 0x53, 0x41, 0x56,
		0x01, 0x00, 0x00, 0x00,
		0x20, 0x00, 0x00, 0x00,
		0x01, 0x00, 0x00, 0x00,
		0x01, 0x00, 0x00, 0x00,
		0x01, 0x00, 0x00, 0x00,
		0x04, 0x00, 0x00, 0x00,
		0x8E, 0x94, 0x10, 0x09,
		0x10, 0x20, 0x30, 0x40,
	};
	bPassed &= TestTrue(TEXT("Serialization matches the exact golden vector"), Serialized == GoldenBytes);

	TArray<uint8> RepeatedSerialization = {0xFF};
	bPassed &= TestEqual(
		TEXT("The golden payload serializes a second time"),
		FBSSaveEnvelope::TrySerialize(Policy, Payload, RepeatedSerialization),
		EBSSaveEnvelopeResult::Succeeded);
	bPassed &= TestTrue(
		TEXT("Repeated serialization is byte-for-byte deterministic"),
		RepeatedSerialization == Serialized);

	FBSSaveEnvelopeHeader Header;
	TArray<uint8> RoundTripPayload = {0xFF};
	bPassed &= TestEqual(
		TEXT("The golden envelope deserializes"),
		FBSSaveEnvelope::TryDeserialize(Policy, Serialized, Header, RoundTripPayload),
		EBSSaveEnvelopeResult::Succeeded);
	bPassed &= TestTrue(TEXT("The round-trip header is valid"), Header.IsValid());
	bPassed &= TestEqual(TEXT("The round-trip payload size is exact"), Header.GetPayloadSize(), 4u);
	bPassed &= TestEqual(TEXT("The round-trip checksum is exact"), Header.GetEnvelopeChecksum(), 0x0910948Eu);
	bPassed &= TestTrue(TEXT("The round-trip payload is exact"), RoundTripPayload == Payload);

	const TArray<uint8> EmptyPayload;
	TArray<uint8> EmptyEnvelope;
	bPassed &= TestEqual(
		TEXT("An empty payload serializes"),
		FBSSaveEnvelope::TrySerialize(Policy, EmptyPayload, EmptyEnvelope),
		EBSSaveEnvelopeResult::Succeeded);
	bPassed &= TestEqual(
		TEXT("An empty envelope contains only its fixed header"),
		EmptyEnvelope.Num(),
		static_cast<int32>(FBSSaveEnvelopeHeader::SerializedSize));
	bPassed &= TestEqual(
		TEXT("An empty payload deserializes"),
		FBSSaveEnvelope::TryDeserialize(Policy, EmptyEnvelope, Header, RoundTripPayload),
		EBSSaveEnvelopeResult::Succeeded);
	bPassed &= TestEqual(TEXT("The empty payload remains empty"), RoundTripPayload.Num(), 0);

	return bPassed;
}

IMPLEMENT_SIMPLE_AUTOMATION_TEST(
	FBrokenStreetsSaveEnvelopeCompatibilityTest,
	"BrokenStreets.Save.Envelope.Compatibility",
	EAutomationTestFlags::EditorContext | EAutomationTestFlags::EngineFilter)

bool FBrokenStreetsSaveEnvelopeCompatibilityTest::RunTest(const FString& Parameters)
{
	bool bPassed = true;

	FBSCompatibilityPolicy LocalPolicy;
	bPassed &= TestTrue(TEXT("The local compatibility policy is valid"), CreatePolicy(3, 4, 5, 2, LocalPolicy));
	const TArray<uint8> Payload = {0xA1, 0xB2, 0xC3};

	FBSCompatibilitySignature StaleSignature;
	bPassed &= TestTrue(
		TEXT("The stale output signature fixture is valid"),
		FBSCompatibilitySignature::TryCreate(8, 8, 8, StaleSignature));

	auto ExpectCompatibilityFailure = [this, &bPassed, &StaleSignature](
		const TCHAR* Description,
		const FBSCompatibilityPolicy& ReadPolicy,
		const TArray<uint8>& Envelope,
		const EBSSaveEnvelopeResult ExpectedResult)
	{
		FBSSaveEnvelopeHeader Header;
		bPassed &= TestTrue(
			TEXT("The stale output header can be primed"),
			FBSSaveEnvelopeHeader::TryCreate(StaleSignature, 1, 1, Header));
		TArray<uint8> ReadPayload = {0xFF};
		bPassed &= TestEqual(
			Description,
			FBSSaveEnvelope::TryDeserialize(ReadPolicy, Envelope, Header, ReadPayload),
			ExpectedResult);
		bPassed &= TestFalse(TEXT("A rejected compatibility read clears the header"), Header.IsValid());
		bPassed &= TestEqual(TEXT("A rejected compatibility read clears the payload"), ReadPayload.Num(), 0);
	};

	auto SerializeCandidate = [this, &bPassed, &Payload](
		const uint32 BuildVersion,
		const uint32 ContentVersion,
		const uint32 SaveVersion,
		TArray<uint8>& OutEnvelope)
	{
		FBSCompatibilityPolicy CandidatePolicy;
		bPassed &= TestTrue(
			TEXT("The candidate compatibility policy is valid"),
			CreatePolicy(BuildVersion, ContentVersion, SaveVersion, 1, CandidatePolicy));
		bPassed &= TestEqual(
			TEXT("The candidate envelope serializes"),
			FBSSaveEnvelope::TrySerialize(CandidatePolicy, Payload, OutEnvelope),
			EBSSaveEnvelopeResult::Succeeded);
	};

	TArray<uint8> Envelope;
	SerializeCandidate(3, 4, 5, Envelope);
	ExpectCompatibilityFailure(
		TEXT("An invalid local policy fails closed first"),
		FBSCompatibilityPolicy(),
		Envelope,
		EBSSaveEnvelopeResult::InvalidPolicy);

	SerializeCandidate(9, 4, 5, Envelope);
	ExpectCompatibilityFailure(
		TEXT("A build mismatch is rejected"),
		LocalPolicy,
		Envelope,
		EBSSaveEnvelopeResult::BuildVersionMismatch);

	SerializeCandidate(3, 9, 5, Envelope);
	ExpectCompatibilityFailure(
		TEXT("A content mismatch is rejected"),
		LocalPolicy,
		Envelope,
		EBSSaveEnvelopeResult::ContentVersionMismatch);

	SerializeCandidate(3, 4, 1, Envelope);
	ExpectCompatibilityFailure(
		TEXT("A save schema below the readable range is rejected"),
		LocalPolicy,
		Envelope,
		EBSSaveEnvelopeResult::SaveSchemaTooOld);

	SerializeCandidate(3, 4, 6, Envelope);
	ExpectCompatibilityFailure(
		TEXT("A save schema above the current version is rejected"),
		LocalPolicy,
		Envelope,
		EBSSaveEnvelopeResult::SaveSchemaTooNew);

	SerializeCandidate(3, 4, 5, Envelope);
	WriteUInt32LittleEndian(Envelope, SaveSchemaVersionOffset, 0);
	RefreshChecksum(Envelope);
	ExpectCompatibilityFailure(
		TEXT("A checksum-valid zero compatibility field is rejected"),
		LocalPolicy,
		Envelope,
		EBSSaveEnvelopeResult::InvalidCompatibilitySignature);

	TArray<uint8> StaleSerialized = {0xFF};
	bPassed &= TestEqual(
		TEXT("Serialization rejects an invalid local policy"),
		FBSSaveEnvelope::TrySerialize(FBSCompatibilityPolicy(), Payload, StaleSerialized),
		EBSSaveEnvelopeResult::InvalidPolicy);
	bPassed &= TestEqual(TEXT("Rejected serialization clears prior output bytes"), StaleSerialized.Num(), 0);

	return bPassed;
}

IMPLEMENT_SIMPLE_AUTOMATION_TEST(
	FBrokenStreetsSaveEnvelopeFaultMatrixTest,
	"BrokenStreets.Save.Envelope.FaultMatrix",
	EAutomationTestFlags::EditorContext | EAutomationTestFlags::EngineFilter)

bool FBrokenStreetsSaveEnvelopeFaultMatrixTest::RunTest(const FString& Parameters)
{
	bool bPassed = true;

	FBSCompatibilityPolicy Policy;
	bPassed &= TestTrue(TEXT("The fault-matrix policy is valid"), CreatePolicy(1, 1, 1, 1, Policy));
	const TArray<uint8> Payload = {0x10, 0x20, 0x30, 0x40};
	TArray<uint8> ValidEnvelope;
	bPassed &= TestEqual(
		TEXT("The fault-matrix source envelope serializes"),
		FBSSaveEnvelope::TrySerialize(Policy, Payload, ValidEnvelope),
		EBSSaveEnvelopeResult::Succeeded);

	FBSCompatibilitySignature StaleSignature;
	bPassed &= TestTrue(
		TEXT("The fault-matrix stale signature is valid"),
		FBSCompatibilitySignature::TryCreate(8, 8, 8, StaleSignature));

	auto ExpectFailure = [this, &bPassed, &Policy, &StaleSignature](
		const TCHAR* Description,
		const TConstArrayView<uint8> Candidate,
		const EBSSaveEnvelopeResult ExpectedResult)
	{
		FBSSaveEnvelopeHeader Header;
		bPassed &= TestTrue(
			TEXT("The fault-matrix stale header can be primed"),
			FBSSaveEnvelopeHeader::TryCreate(StaleSignature, 1, 1, Header));
		TArray<uint8> ReadPayload = {0xFF};
		bPassed &= TestEqual(
			Description,
			FBSSaveEnvelope::TryDeserialize(Policy, Candidate, Header, ReadPayload),
			ExpectedResult);
		bPassed &= TestFalse(TEXT("A failed fault-matrix read clears the header"), Header.IsValid());
		bPassed &= TestEqual(TEXT("A failed fault-matrix read clears the payload"), ReadPayload.Num(), 0);
	};

	for (int32 PrefixLength = 0; PrefixLength < ValidEnvelope.Num(); ++PrefixLength)
	{
		const EBSSaveEnvelopeResult ExpectedResult = PrefixLength < static_cast<int32>(FBSSaveEnvelopeHeader::SerializedSize)
			? EBSSaveEnvelopeResult::HeaderTruncated
			: EBSSaveEnvelopeResult::FileSizeMismatch;
		ExpectFailure(
			*FString::Printf(TEXT("Truncated prefix length %d is rejected"), PrefixLength),
			MakeArrayView(ValidEnvelope.GetData(), PrefixLength),
			ExpectedResult);
	}

	TArray<uint8> Candidate = ValidEnvelope;
	Candidate[0] ^= 0x01;
	ExpectFailure(TEXT("An invalid magic value is rejected"), Candidate, EBSSaveEnvelopeResult::InvalidMagic);

	Candidate = ValidEnvelope;
	WriteUInt32LittleEndian(Candidate, 4, 2);
	ExpectFailure(
		TEXT("An unsupported envelope format version is rejected"),
		Candidate,
		EBSSaveEnvelopeResult::UnsupportedFormatVersion);

	Candidate = ValidEnvelope;
	WriteUInt32LittleEndian(Candidate, 8, FBSSaveEnvelopeHeader::SerializedSize - 1);
	ExpectFailure(TEXT("An invalid fixed header size is rejected"), Candidate, EBSSaveEnvelopeResult::InvalidHeaderSize);

	Candidate = ValidEnvelope;
	WriteUInt32LittleEndian(
		Candidate,
		PayloadSizeOffset,
		static_cast<uint32>(FBSSaveEnvelopeHeader::MaxPayloadSize + 1));
	ExpectFailure(TEXT("A declared payload above the cap is rejected"), Candidate, EBSSaveEnvelopeResult::PayloadTooLarge);

	Candidate = ValidEnvelope;
	WriteUInt32LittleEndian(Candidate, PayloadSizeOffset, static_cast<uint32>(Payload.Num() - 1));
	ExpectFailure(TEXT("A declared payload size mismatch is rejected"), Candidate, EBSSaveEnvelopeResult::FileSizeMismatch);

	Candidate = ValidEnvelope;
	Candidate.Add(0xFF);
	ExpectFailure(TEXT("Trailing bytes are rejected"), Candidate, EBSSaveEnvelopeResult::FileSizeMismatch);

	Candidate = ValidEnvelope;
	Candidate[ChecksumOffset] ^= 0x01;
	ExpectFailure(TEXT("A corrupted checksum field is rejected"), Candidate, EBSSaveEnvelopeResult::ChecksumMismatch);

	Candidate = ValidEnvelope;
	Candidate.Last() ^= 0x01;
	ExpectFailure(TEXT("A corrupted payload byte is rejected"), Candidate, EBSSaveEnvelopeResult::ChecksumMismatch);

	return bPassed;
}

#endif // WITH_DEV_AUTOMATION_TESTS
