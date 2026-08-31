// Copyright Madalin Gavrila. All Rights Reserved.

#pragma once

#include "CoreMinimal.h"
#include "Core/Identity/BSIdentifiers.h"

/**
 * Bounded, single-line context for a Broken Streets log message.
 *
 * Operation names use lowercase ASCII snake_case. Optional identity fields
 * accept only already-valid Core identifiers. Free-form values are deliberately
 * excluded so callers cannot accidentally place private or untrusted text into
 * the structured portion of a log.
 */
class BROKENSTREETS_API FBSLogContext final
{
public:
	static constexpr int32 MaxOperationLength = 64;

	FBSLogContext() = default;

	/** Creates a context and clears OutContext on every failure. */
	[[nodiscard]] static bool TryCreate(const FString& Operation, FBSLogContext& OutContext);

	/** Assigns a valid definition identifier. Invalid input clears this optional field. */
	[[nodiscard]] bool TrySetDefinitionId(const FBSDefinitionId& InDefinitionId);

	/** Assigns a valid instance identifier. Invalid input clears this optional field. */
	[[nodiscard]] bool TrySetInstanceId(const FBSInstanceId& InInstanceId);

	[[nodiscard]] bool IsValid() const;
	[[nodiscard]] bool HasDefinitionId() const;
	[[nodiscard]] bool HasInstanceId() const;
	[[nodiscard]] const FString& GetOperation() const;

	/** Returns deterministic key/value fields, or an empty string for an invalid context. */
	[[nodiscard]] FString ToLogString() const;

	void Reset();

private:
	FString OperationValue;
	FBSDefinitionId DefinitionId;
	FBSInstanceId InstanceId;
};
