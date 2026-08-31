// Copyright Madalin Gavrila. All Rights Reserved.

#pragma once

#include "CoreMinimal.h"

/** Closed machine-readable outcome. It grants no automatic retry or recovery behavior. */
enum class EBSResultStatus : uint8
{
	Invalid,
	Succeeded,
	Rejected,
	Failed,
};

/** Bounded machine error in canonical <domain>.<reason> form; never player-facing text. */
struct BROKENSTREETS_API FBSErrorCode final
{
public:
	static constexpr int32 MaxSegmentLength = 64;

	FBSErrorCode() = default;

	/** Parses canonical text and clears OutCode on every failure. */
	[[nodiscard]] static bool TryParse(const FString& Text, FBSErrorCode& OutCode);

	[[nodiscard]] bool IsValid() const;
	[[nodiscard]] FString ToString() const;

	void Reset();

	[[nodiscard]] bool operator==(const FBSErrorCode& Other) const
	{
		return CanonicalValue.Equals(Other.CanonicalValue, ESearchCase::CaseSensitive);
	}

	[[nodiscard]] bool operator!=(const FBSErrorCode& Other) const
	{
		return !(*this == Other);
	}

	friend uint32 GetTypeHash(const FBSErrorCode& Code)
	{
		return GetTypeHash(Code.CanonicalValue);
	}

private:
	FString CanonicalValue;
};

/** Invariant result metadata for a future typed domain result payload. */
struct BROKENSTREETS_API FBSResult final
{
public:
	FBSResult() = default;

	/** Creates a valid success with no error code. */
	[[nodiscard]] static FBSResult Succeeded();

	/** Creates a valid deliberate rejection and clears OutResult on failure. */
	[[nodiscard]] static bool TryCreateRejected(
		const FBSErrorCode& ErrorCode,
		FBSResult& OutResult);

	/** Creates a valid execution failure and clears OutResult on failure. */
	[[nodiscard]] static bool TryCreateFailed(
		const FBSErrorCode& ErrorCode,
		FBSResult& OutResult);

	[[nodiscard]] bool IsValid() const;
	[[nodiscard]] bool IsSucceeded() const;
	[[nodiscard]] bool IsRejected() const;
	[[nodiscard]] bool IsFailed() const;
	[[nodiscard]] EBSResultStatus GetStatus() const;
	[[nodiscard]] const FBSErrorCode& GetErrorCode() const;

	/** Returns a stable lowercase machine name; unknown enum values return "unknown". */
	[[nodiscard]] static const TCHAR* GetStableName(EBSResultStatus Status);

	void Reset();

private:
	[[nodiscard]] static bool TryCreateWithError(
		EBSResultStatus Status,
		const FBSErrorCode& ErrorCode,
		FBSResult& OutResult);

	EBSResultStatus StatusValue = EBSResultStatus::Invalid;
	FBSErrorCode ErrorCodeValue;
};
