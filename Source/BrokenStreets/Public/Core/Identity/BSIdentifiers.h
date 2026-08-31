// Copyright Madalin Gavrila. All Rights Reserved.

#pragma once

#include "CoreMinimal.h"
#include "UObject/PrimaryAssetId.h"

#include "BSIdentifiers.generated.h"

/**
 * Stable identity for one catalog definition.
 *
 * Canonical text uses <type>:<name>. Each segment contains 1-64 lowercase ASCII
 * letters, digits, or underscores and starts with a letter. The value is not an
 * asset path and must survive asset renames and moves.
 */
USTRUCT(BlueprintType)
struct BROKENSTREETS_API FBSDefinitionId
{
	GENERATED_BODY()

public:
	static constexpr int32 MaxSegmentLength = 64;

	FBSDefinitionId() = default;

	/** Parses canonical text and clears OutId on every failure. */
	[[nodiscard]] static bool TryParse(const FString& Text, FBSDefinitionId& OutId);

	[[nodiscard]] bool IsValid() const;
	[[nodiscard]] FString ToString() const;
	[[nodiscard]] FPrimaryAssetId ToPrimaryAssetId() const;

	void Reset();

	[[nodiscard]] bool operator==(const FBSDefinitionId& Other) const
	{
		return CanonicalValue.Equals(Other.CanonicalValue, ESearchCase::CaseSensitive);
	}

	[[nodiscard]] bool operator!=(const FBSDefinitionId& Other) const
	{
		return !(*this == Other);
	}

	friend uint32 GetTypeHash(const FBSDefinitionId& Id)
	{
		return GetTypeHash(Id.CanonicalValue);
	}

	friend FArchive& operator<<(FArchive& Archive, FBSDefinitionId& Id)
	{
		Archive << Id.CanonicalValue;
		return Archive;
	}

private:
	UPROPERTY(EditAnywhere, SaveGame, BlueprintReadOnly, Category = "Broken Streets|Identity", meta = (AllowPrivateAccess = "true"))
	FString CanonicalValue;
};

template <>
struct TStructOpsTypeTraits<FBSDefinitionId> : public TStructOpsTypeTraitsBase2<FBSDefinitionId>
{
	enum
	{
		WithIdenticalViaEquality = true,
	};
};

/** Unique identity for one logical runtime or persistent instance. */
USTRUCT(BlueprintType)
struct BROKENSTREETS_API FBSInstanceId
{
	GENERATED_BODY()

public:
	FBSInstanceId() = default;

	/** Produces a new non-zero identifier. The future domain owner decides when to call it. */
	[[nodiscard]] static FBSInstanceId Create();

	/** Accepts only the canonical lowercase hyphenated GUID form and clears OutId on failure. */
	[[nodiscard]] static bool TryParse(const FString& Text, FBSInstanceId& OutId);

	[[nodiscard]] bool IsValid() const;
	[[nodiscard]] FString ToString() const;
	[[nodiscard]] const FGuid& GetGuid() const;

	void Reset();

	[[nodiscard]] bool operator==(const FBSInstanceId& Other) const
	{
		return Value == Other.Value;
	}

	[[nodiscard]] bool operator!=(const FBSInstanceId& Other) const
	{
		return !(*this == Other);
	}

	friend uint32 GetTypeHash(const FBSInstanceId& Id)
	{
		return GetTypeHash(Id.Value);
	}

	friend FArchive& operator<<(FArchive& Archive, FBSInstanceId& Id)
	{
		Archive << Id.Value;
		return Archive;
	}

private:
	UPROPERTY(SaveGame, BlueprintReadOnly, Category = "Broken Streets|Identity", meta = (AllowPrivateAccess = "true"))
	FGuid Value;
};

template <>
struct TStructOpsTypeTraits<FBSInstanceId> : public TStructOpsTypeTraitsBase2<FBSInstanceId>
{
	enum
	{
		WithIdenticalViaEquality = true,
	};
};
