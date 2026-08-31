// Copyright Madalin Gavrila. All Rights Reserved.

#pragma once

#include "CoreMinimal.h"

/** Stable result of evaluating one peer or profile compatibility signature. */
enum class EBSCompatibilityResult : uint8
{
	Compatible,
	InvalidPolicy,
	InvalidSignature,
	BuildVersionMismatch,
	ContentVersionMismatch,
	SaveSchemaTooOld,
	SaveSchemaTooNew,
};

/** Immutable compatibility values presented by a future peer or persisted profile header. */
struct BROKENSTREETS_API FBSCompatibilitySignature final
{
public:
	FBSCompatibilitySignature() = default;

	/** Creates a signature only when every version is non-zero. Failure clears OutSignature. */
	[[nodiscard]] static bool TryCreate(
		uint32 BuildCompatibilityVersion,
		uint32 ContentCompatibilityVersion,
		uint32 SaveSchemaVersion,
		FBSCompatibilitySignature& OutSignature);

	[[nodiscard]] bool IsValid() const;
	[[nodiscard]] uint32 GetBuildCompatibilityVersion() const;
	[[nodiscard]] uint32 GetContentCompatibilityVersion() const;
	[[nodiscard]] uint32 GetSaveSchemaVersion() const;

	void Reset();

private:
	uint32 BuildVersion = 0;
	uint32 ContentVersion = 0;
	uint32 SaveVersion = 0;
};

/** Local acceptance policy: exact build/content lanes and an inclusive readable save-schema range. */
struct BROKENSTREETS_API FBSCompatibilityPolicy final
{
public:
	FBSCompatibilityPolicy() = default;

	/** Creates a policy only when versions are non-zero and MinimumReadable <= Current. Failure clears OutPolicy. */
	[[nodiscard]] static bool TryCreate(
		uint32 BuildCompatibilityVersion,
		uint32 ContentCompatibilityVersion,
		uint32 CurrentSaveSchemaVersion,
		uint32 MinimumReadableSaveSchemaVersion,
		FBSCompatibilityPolicy& OutPolicy);

	[[nodiscard]] bool IsValid() const;
	[[nodiscard]] uint32 GetBuildCompatibilityVersion() const;
	[[nodiscard]] uint32 GetContentCompatibilityVersion() const;
	[[nodiscard]] uint32 GetCurrentSaveSchemaVersion() const;
	[[nodiscard]] uint32 GetMinimumReadableSaveSchemaVersion() const;
	[[nodiscard]] FBSCompatibilitySignature GetCurrentSignature() const;

	void Reset();

private:
	uint32 BuildVersion = 0;
	uint32 ContentVersion = 0;
	uint32 CurrentSaveVersion = 0;
	uint32 MinimumReadableSaveVersion = 0;
};

/** Pure, fail-closed compatibility parsing, configuration, and evaluation boundary. */
class BROKENSTREETS_API FBSCompatibility final
{
public:
	/** Accepts canonical unsigned decimal text in the inclusive range 1..MAX_uint32. Failure clears OutVersion. */
	[[nodiscard]] static bool TryParseVersion(const FString& Text, uint32& OutVersion);

	/** Loads the four project-owned values from [BrokenStreets.Compatibility]. Failure clears OutPolicy. */
	[[nodiscard]] static bool TryLoadCurrentPolicy(FBSCompatibilityPolicy& OutPolicy);

	/** Evaluates in fixed order: validity, build, content, too-old save, then too-new save. */
	[[nodiscard]] static EBSCompatibilityResult Evaluate(
		const FBSCompatibilityPolicy& Policy,
		const FBSCompatibilitySignature& Signature);

	/** Returns a stable lowercase machine name; unknown enum values return "unknown". */
	[[nodiscard]] static const TCHAR* GetStableName(EBSCompatibilityResult Result);
};
