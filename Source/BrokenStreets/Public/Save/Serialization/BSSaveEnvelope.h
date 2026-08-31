// Copyright Madalin Gavrila. All Rights Reserved.

#pragma once

#include "CoreMinimal.h"
#include "Core/Compatibility/BSCompatibility.h"

/** Stable result returned by the pure save-envelope boundary. */
enum class EBSSaveEnvelopeResult : uint8
{
	Succeeded,
	InvalidPolicy,
	PayloadTooLarge,
	HeaderTruncated,
	InvalidMagic,
	UnsupportedFormatVersion,
	InvalidHeaderSize,
	FileSizeMismatch,
	ChecksumMismatch,
	InvalidCompatibilitySignature,
	BuildVersionMismatch,
	ContentVersionMismatch,
	SaveSchemaTooOld,
	SaveSchemaTooNew,
};

/** Validated metadata recovered from, or written to, one save envelope. */
struct BROKENSTREETS_API FBSSaveEnvelopeHeader final
{
public:
	static constexpr uint32 EnvelopeFormatVersion = 1;
	static constexpr uint32 SerializedSize = 32;
	static constexpr uint64 MaxPayloadSize = 64ull * 1024ull * 1024ull;

	/** Creates a header only when the signature and payload size are valid. Failure clears OutHeader. */
	[[nodiscard]] static bool TryCreate(
		const FBSCompatibilitySignature& CompatibilitySignature,
		uint64 PayloadSize,
		uint32 EnvelopeChecksum,
		FBSSaveEnvelopeHeader& OutHeader);

	[[nodiscard]] bool IsValid() const;
	[[nodiscard]] uint32 GetEnvelopeFormatVersion() const;
	[[nodiscard]] uint32 GetSerializedHeaderSize() const;
	[[nodiscard]] const FBSCompatibilitySignature& GetCompatibilitySignature() const;
	[[nodiscard]] uint32 GetPayloadSize() const;
	[[nodiscard]] uint32 GetEnvelopeChecksum() const;

	void Reset();

private:
	FBSCompatibilitySignature Signature;
	uint32 PayloadSize = 0;
	uint32 Checksum = 0;
};

/** Pure, deterministic, fail-closed serializer for the minimum Broken Streets save envelope. */
class BROKENSTREETS_API FBSSaveEnvelope final
{
public:
	/** Serializes a validated compatibility signature and opaque payload. Failure clears OutBytes. */
	[[nodiscard]] static EBSSaveEnvelopeResult TrySerialize(
		const FBSCompatibilityPolicy& Policy,
		TConstArrayView<uint8> Payload,
		TArray<uint8>& OutBytes);

	/** Validates and deserializes a complete envelope. Failure clears both outputs. */
	[[nodiscard]] static EBSSaveEnvelopeResult TryDeserialize(
		const FBSCompatibilityPolicy& Policy,
		TConstArrayView<uint8> Bytes,
		FBSSaveEnvelopeHeader& OutHeader,
		TArray<uint8>& OutPayload);

	/** Returns a stable lowercase machine name; unknown enum values return "unknown". */
	[[nodiscard]] static const TCHAR* GetStableName(EBSSaveEnvelopeResult Result);
};
