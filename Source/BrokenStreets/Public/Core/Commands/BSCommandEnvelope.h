// Copyright Madalin Gavrila. All Rights Reserved.

#pragma once

#include "CoreMinimal.h"

/** Unique identity of one logical command. Reuse it only when retrying that same logical command. */
struct BROKENSTREETS_API FBSCommandId final
{
public:
	FBSCommandId() = default;

	/** Produces a new non-zero command identifier. */
	[[nodiscard]] static FBSCommandId Create();

	/** Accepts only canonical lowercase hyphenated GUID text and clears OutId on failure. */
	[[nodiscard]] static bool TryParse(const FString& Text, FBSCommandId& OutId);

	[[nodiscard]] bool IsValid() const;
	[[nodiscard]] FString ToString() const;
	[[nodiscard]] const FGuid& GetGuid() const;

	void Reset();

	[[nodiscard]] bool operator==(const FBSCommandId& Other) const
	{
		return Value == Other.Value;
	}

	[[nodiscard]] bool operator!=(const FBSCommandId& Other) const
	{
		return !(*this == Other);
	}

	friend uint32 GetTypeHash(const FBSCommandId& Id)
	{
		return GetTypeHash(Id.Value);
	}

private:
	FGuid Value;
};

/** Groups a root command and its explicitly created child work. It is not an idempotency key. */
struct BROKENSTREETS_API FBSCorrelationId final
{
public:
	FBSCorrelationId() = default;

	/** Produces a new non-zero correlation identifier. */
	[[nodiscard]] static FBSCorrelationId Create();

	/** Accepts only canonical lowercase hyphenated GUID text and clears OutId on failure. */
	[[nodiscard]] static bool TryParse(const FString& Text, FBSCorrelationId& OutId);

	[[nodiscard]] bool IsValid() const;
	[[nodiscard]] FString ToString() const;
	[[nodiscard]] const FGuid& GetGuid() const;

	void Reset();

	[[nodiscard]] bool operator==(const FBSCorrelationId& Other) const
	{
		return Value == Other.Value;
	}

	[[nodiscard]] bool operator!=(const FBSCorrelationId& Other) const
	{
		return !(*this == Other);
	}

	friend uint32 GetTypeHash(const FBSCorrelationId& Id)
	{
		return GetTypeHash(Id.Value);
	}

private:
	FGuid Value;
};

/** Minimal metadata carried beside a future typed command payload. */
struct BROKENSTREETS_API FBSCommandEnvelope final
{
public:
	FBSCommandEnvelope() = default;

	/** Creates a valid root envelope with distinct generated command and correlation identifiers. */
	[[nodiscard]] static FBSCommandEnvelope CreateRoot();

	/** Creates an envelope from already-valid identifiers and clears OutEnvelope on failure. */
	[[nodiscard]] static bool TryCreate(
		const FBSCommandId& CommandId,
		const FBSCorrelationId& CorrelationId,
		FBSCommandEnvelope& OutEnvelope);

	/** Creates a new command under Parent's correlation and clears OutEnvelope on failure. */
	[[nodiscard]] static bool TryCreateChild(
		const FBSCommandEnvelope& Parent,
		FBSCommandEnvelope& OutEnvelope);

	[[nodiscard]] bool IsValid() const;
	[[nodiscard]] const FBSCommandId& GetCommandId() const;
	[[nodiscard]] const FBSCorrelationId& GetCorrelationId() const;

	void Reset();

private:
	FBSCommandId CommandIdValue;
	FBSCorrelationId CorrelationIdValue;
};
