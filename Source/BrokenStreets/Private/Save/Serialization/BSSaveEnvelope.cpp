// Copyright Madalin Gavrila. All Rights Reserved.

#include "Save/Serialization/BSSaveEnvelope.h"

#include "Misc/Crc.h"

namespace
{
constexpr uint8 SaveEnvelopeMagic[] = {0x42, 0x53, 0x41, 0x56};

constexpr int32 MagicOffset = 0;
constexpr int32 EnvelopeFormatVersionOffset = 4;
constexpr int32 HeaderSizeOffset = 8;
constexpr int32 BuildCompatibilityVersionOffset = 12;
constexpr int32 ContentCompatibilityVersionOffset = 16;
constexpr int32 SaveSchemaVersionOffset = 20;
constexpr int32 PayloadSizeOffset = 24;
constexpr int32 ChecksumOffset = 28;

void AppendUInt32LittleEndian(TArray<uint8>& Bytes, const uint32 Value)
{
	Bytes.Add(static_cast<uint8>(Value));
	Bytes.Add(static_cast<uint8>(Value >> 8));
	Bytes.Add(static_cast<uint8>(Value >> 16));
	Bytes.Add(static_cast<uint8>(Value >> 24));
}

uint32 ReadUInt32LittleEndian(const TConstArrayView<uint8> Bytes, const int32 Offset)
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

uint32 CalculateEnvelopeChecksum(const TConstArrayView<uint8> Bytes, const uint32 PayloadSize)
{
	uint32 Result = FCrc::MemCrc32(Bytes.GetData(), ChecksumOffset);
	if (PayloadSize > 0)
	{
		Result = FCrc::MemCrc32(
			Bytes.GetData() + FBSSaveEnvelopeHeader::SerializedSize,
			PayloadSize,
			Result);
	}
	return Result;
}

EBSSaveEnvelopeResult TranslateCompatibilityResult(const EBSCompatibilityResult Result)
{
	switch (Result)
	{
	case EBSCompatibilityResult::Compatible:
		return EBSSaveEnvelopeResult::Succeeded;
	case EBSCompatibilityResult::InvalidPolicy:
		return EBSSaveEnvelopeResult::InvalidPolicy;
	case EBSCompatibilityResult::InvalidSignature:
		return EBSSaveEnvelopeResult::InvalidCompatibilitySignature;
	case EBSCompatibilityResult::BuildVersionMismatch:
		return EBSSaveEnvelopeResult::BuildVersionMismatch;
	case EBSCompatibilityResult::ContentVersionMismatch:
		return EBSSaveEnvelopeResult::ContentVersionMismatch;
	case EBSCompatibilityResult::SaveSchemaTooOld:
		return EBSSaveEnvelopeResult::SaveSchemaTooOld;
	case EBSCompatibilityResult::SaveSchemaTooNew:
		return EBSSaveEnvelopeResult::SaveSchemaTooNew;
	default:
		return EBSSaveEnvelopeResult::InvalidCompatibilitySignature;
	}
}
} // namespace

bool FBSSaveEnvelopeHeader::TryCreate(
	const FBSCompatibilitySignature& CompatibilitySignature,
	const uint64 InPayloadSize,
	const uint32 EnvelopeChecksum,
	FBSSaveEnvelopeHeader& OutHeader)
{
	OutHeader.Reset();

	if (!CompatibilitySignature.IsValid() || InPayloadSize > MaxPayloadSize)
	{
		return false;
	}

	OutHeader.Signature = CompatibilitySignature;
	OutHeader.PayloadSize = static_cast<uint32>(InPayloadSize);
	OutHeader.Checksum = EnvelopeChecksum;
	return true;
}

bool FBSSaveEnvelopeHeader::IsValid() const
{
	return Signature.IsValid() && static_cast<uint64>(PayloadSize) <= MaxPayloadSize;
}

uint32 FBSSaveEnvelopeHeader::GetEnvelopeFormatVersion() const
{
	return EnvelopeFormatVersion;
}

uint32 FBSSaveEnvelopeHeader::GetSerializedHeaderSize() const
{
	return SerializedSize;
}

const FBSCompatibilitySignature& FBSSaveEnvelopeHeader::GetCompatibilitySignature() const
{
	return Signature;
}

uint32 FBSSaveEnvelopeHeader::GetPayloadSize() const
{
	return PayloadSize;
}

uint32 FBSSaveEnvelopeHeader::GetEnvelopeChecksum() const
{
	return Checksum;
}

void FBSSaveEnvelopeHeader::Reset()
{
	Signature.Reset();
	PayloadSize = 0;
	Checksum = 0;
}

EBSSaveEnvelopeResult FBSSaveEnvelope::TrySerialize(
	const FBSCompatibilityPolicy& Policy,
	const TConstArrayView<uint8> Payload,
	TArray<uint8>& OutBytes)
{
	OutBytes.Reset();

	if (!Policy.IsValid())
	{
		return EBSSaveEnvelopeResult::InvalidPolicy;
	}

	if (static_cast<uint64>(Payload.Num()) > FBSSaveEnvelopeHeader::MaxPayloadSize)
	{
		return EBSSaveEnvelopeResult::PayloadTooLarge;
	}

	const FBSCompatibilitySignature Signature = Policy.GetCurrentSignature();
	if (!Signature.IsValid())
	{
		return EBSSaveEnvelopeResult::InvalidPolicy;
	}

	OutBytes.Reserve(FBSSaveEnvelopeHeader::SerializedSize + Payload.Num());
	OutBytes.Append(SaveEnvelopeMagic, UE_ARRAY_COUNT(SaveEnvelopeMagic));
	AppendUInt32LittleEndian(OutBytes, FBSSaveEnvelopeHeader::EnvelopeFormatVersion);
	AppendUInt32LittleEndian(OutBytes, FBSSaveEnvelopeHeader::SerializedSize);
	AppendUInt32LittleEndian(OutBytes, Signature.GetBuildCompatibilityVersion());
	AppendUInt32LittleEndian(OutBytes, Signature.GetContentCompatibilityVersion());
	AppendUInt32LittleEndian(OutBytes, Signature.GetSaveSchemaVersion());
	AppendUInt32LittleEndian(OutBytes, static_cast<uint32>(Payload.Num()));
	AppendUInt32LittleEndian(OutBytes, 0);
	OutBytes.Append(Payload.GetData(), Payload.Num());

	const uint32 Checksum = CalculateEnvelopeChecksum(OutBytes, static_cast<uint32>(Payload.Num()));
	WriteUInt32LittleEndian(OutBytes, ChecksumOffset, Checksum);
	return EBSSaveEnvelopeResult::Succeeded;
}

EBSSaveEnvelopeResult FBSSaveEnvelope::TryDeserialize(
	const FBSCompatibilityPolicy& Policy,
	const TConstArrayView<uint8> Bytes,
	FBSSaveEnvelopeHeader& OutHeader,
	TArray<uint8>& OutPayload)
{
	OutHeader.Reset();
	OutPayload.Reset();

	if (Bytes.Num() < static_cast<int32>(FBSSaveEnvelopeHeader::SerializedSize))
	{
		return EBSSaveEnvelopeResult::HeaderTruncated;
	}

	if (FMemory::Memcmp(Bytes.GetData() + MagicOffset, SaveEnvelopeMagic, UE_ARRAY_COUNT(SaveEnvelopeMagic)) != 0)
	{
		return EBSSaveEnvelopeResult::InvalidMagic;
	}

	if (ReadUInt32LittleEndian(Bytes, EnvelopeFormatVersionOffset) != FBSSaveEnvelopeHeader::EnvelopeFormatVersion)
	{
		return EBSSaveEnvelopeResult::UnsupportedFormatVersion;
	}

	if (ReadUInt32LittleEndian(Bytes, HeaderSizeOffset) != FBSSaveEnvelopeHeader::SerializedSize)
	{
		return EBSSaveEnvelopeResult::InvalidHeaderSize;
	}

	const uint32 PayloadSize = ReadUInt32LittleEndian(Bytes, PayloadSizeOffset);
	if (static_cast<uint64>(PayloadSize) > FBSSaveEnvelopeHeader::MaxPayloadSize)
	{
		return EBSSaveEnvelopeResult::PayloadTooLarge;
	}

	const uint64 ExpectedSize = static_cast<uint64>(FBSSaveEnvelopeHeader::SerializedSize) + PayloadSize;
	if (ExpectedSize != static_cast<uint64>(Bytes.Num()))
	{
		return EBSSaveEnvelopeResult::FileSizeMismatch;
	}

	const uint32 SerializedChecksum = ReadUInt32LittleEndian(Bytes, ChecksumOffset);
	if (CalculateEnvelopeChecksum(Bytes, PayloadSize) != SerializedChecksum)
	{
		return EBSSaveEnvelopeResult::ChecksumMismatch;
	}

	if (!Policy.IsValid())
	{
		return EBSSaveEnvelopeResult::InvalidPolicy;
	}

	FBSCompatibilitySignature Signature;
	if (!FBSCompatibilitySignature::TryCreate(
		ReadUInt32LittleEndian(Bytes, BuildCompatibilityVersionOffset),
		ReadUInt32LittleEndian(Bytes, ContentCompatibilityVersionOffset),
		ReadUInt32LittleEndian(Bytes, SaveSchemaVersionOffset),
		Signature))
	{
		return EBSSaveEnvelopeResult::InvalidCompatibilitySignature;
	}

	const EBSSaveEnvelopeResult CompatibilityResult = TranslateCompatibilityResult(
		FBSCompatibility::Evaluate(Policy, Signature));
	if (CompatibilityResult != EBSSaveEnvelopeResult::Succeeded)
	{
		return CompatibilityResult;
	}

	FBSSaveEnvelopeHeader Header;
	if (!FBSSaveEnvelopeHeader::TryCreate(Signature, PayloadSize, SerializedChecksum, Header))
	{
		return EBSSaveEnvelopeResult::PayloadTooLarge;
	}

	TArray<uint8> Payload;
	Payload.Append(Bytes.GetData() + FBSSaveEnvelopeHeader::SerializedSize, PayloadSize);

	OutHeader = Header;
	OutPayload = MoveTemp(Payload);
	return EBSSaveEnvelopeResult::Succeeded;
}

const TCHAR* FBSSaveEnvelope::GetStableName(const EBSSaveEnvelopeResult Result)
{
	switch (Result)
	{
	case EBSSaveEnvelopeResult::Succeeded:
		return TEXT("succeeded");
	case EBSSaveEnvelopeResult::InvalidPolicy:
		return TEXT("invalid_policy");
	case EBSSaveEnvelopeResult::PayloadTooLarge:
		return TEXT("payload_too_large");
	case EBSSaveEnvelopeResult::HeaderTruncated:
		return TEXT("header_truncated");
	case EBSSaveEnvelopeResult::InvalidMagic:
		return TEXT("invalid_magic");
	case EBSSaveEnvelopeResult::UnsupportedFormatVersion:
		return TEXT("unsupported_format_version");
	case EBSSaveEnvelopeResult::InvalidHeaderSize:
		return TEXT("invalid_header_size");
	case EBSSaveEnvelopeResult::FileSizeMismatch:
		return TEXT("file_size_mismatch");
	case EBSSaveEnvelopeResult::ChecksumMismatch:
		return TEXT("checksum_mismatch");
	case EBSSaveEnvelopeResult::InvalidCompatibilitySignature:
		return TEXT("invalid_compatibility_signature");
	case EBSSaveEnvelopeResult::BuildVersionMismatch:
		return TEXT("build_version_mismatch");
	case EBSSaveEnvelopeResult::ContentVersionMismatch:
		return TEXT("content_version_mismatch");
	case EBSSaveEnvelopeResult::SaveSchemaTooOld:
		return TEXT("save_schema_too_old");
	case EBSSaveEnvelopeResult::SaveSchemaTooNew:
		return TEXT("save_schema_too_new");
	default:
		return TEXT("unknown");
	}
}
