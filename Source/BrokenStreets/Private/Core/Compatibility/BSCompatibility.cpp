// Copyright Madalin Gavrila. All Rights Reserved.

#include "Core/Compatibility/BSCompatibility.h"

#include "Misc/ConfigCacheIni.h"

namespace
{
constexpr TCHAR CompatibilitySection[] = TEXT("BrokenStreets.Compatibility");
constexpr TCHAR BuildVersionKey[] = TEXT("BuildCompatibilityVersion");
constexpr TCHAR ContentVersionKey[] = TEXT("ContentCompatibilityVersion");
constexpr TCHAR CurrentSaveVersionKey[] = TEXT("CurrentSaveSchemaVersion");
constexpr TCHAR MinimumReadableSaveVersionKey[] = TEXT("MinimumReadableSaveSchemaVersion");

bool TryLoadVersion(const TCHAR* Key, uint32& OutVersion)
{
	OutVersion = 0;

	if (GConfig == nullptr)
	{
		return false;
	}

	FString Text;
	return GConfig->GetString(CompatibilitySection, Key, Text, GGameIni)
		&& FBSCompatibility::TryParseVersion(Text, OutVersion);
}
} // namespace

bool FBSCompatibilitySignature::TryCreate(
	const uint32 BuildCompatibilityVersion,
	const uint32 ContentCompatibilityVersion,
	const uint32 SaveSchemaVersion,
	FBSCompatibilitySignature& OutSignature)
{
	OutSignature.Reset();

	if (BuildCompatibilityVersion == 0 || ContentCompatibilityVersion == 0 || SaveSchemaVersion == 0)
	{
		return false;
	}

	OutSignature.BuildVersion = BuildCompatibilityVersion;
	OutSignature.ContentVersion = ContentCompatibilityVersion;
	OutSignature.SaveVersion = SaveSchemaVersion;
	return true;
}

bool FBSCompatibilitySignature::IsValid() const
{
	return BuildVersion != 0 && ContentVersion != 0 && SaveVersion != 0;
}

uint32 FBSCompatibilitySignature::GetBuildCompatibilityVersion() const
{
	return BuildVersion;
}

uint32 FBSCompatibilitySignature::GetContentCompatibilityVersion() const
{
	return ContentVersion;
}

uint32 FBSCompatibilitySignature::GetSaveSchemaVersion() const
{
	return SaveVersion;
}

void FBSCompatibilitySignature::Reset()
{
	BuildVersion = 0;
	ContentVersion = 0;
	SaveVersion = 0;
}

bool FBSCompatibilityPolicy::TryCreate(
	const uint32 BuildCompatibilityVersion,
	const uint32 ContentCompatibilityVersion,
	const uint32 CurrentSaveSchemaVersion,
	const uint32 MinimumReadableSaveSchemaVersion,
	FBSCompatibilityPolicy& OutPolicy)
{
	OutPolicy.Reset();

	if (BuildCompatibilityVersion == 0
		|| ContentCompatibilityVersion == 0
		|| CurrentSaveSchemaVersion == 0
		|| MinimumReadableSaveSchemaVersion == 0
		|| MinimumReadableSaveSchemaVersion > CurrentSaveSchemaVersion)
	{
		return false;
	}

	OutPolicy.BuildVersion = BuildCompatibilityVersion;
	OutPolicy.ContentVersion = ContentCompatibilityVersion;
	OutPolicy.CurrentSaveVersion = CurrentSaveSchemaVersion;
	OutPolicy.MinimumReadableSaveVersion = MinimumReadableSaveSchemaVersion;
	return true;
}

bool FBSCompatibilityPolicy::IsValid() const
{
	return BuildVersion != 0
		&& ContentVersion != 0
		&& CurrentSaveVersion != 0
		&& MinimumReadableSaveVersion != 0
		&& MinimumReadableSaveVersion <= CurrentSaveVersion;
}

uint32 FBSCompatibilityPolicy::GetBuildCompatibilityVersion() const
{
	return BuildVersion;
}

uint32 FBSCompatibilityPolicy::GetContentCompatibilityVersion() const
{
	return ContentVersion;
}

uint32 FBSCompatibilityPolicy::GetCurrentSaveSchemaVersion() const
{
	return CurrentSaveVersion;
}

uint32 FBSCompatibilityPolicy::GetMinimumReadableSaveSchemaVersion() const
{
	return MinimumReadableSaveVersion;
}

FBSCompatibilitySignature FBSCompatibilityPolicy::GetCurrentSignature() const
{
	FBSCompatibilitySignature Result;
	if (IsValid() && !FBSCompatibilitySignature::TryCreate(BuildVersion, ContentVersion, CurrentSaveVersion, Result))
	{
		Result.Reset();
	}
	return Result;
}

void FBSCompatibilityPolicy::Reset()
{
	BuildVersion = 0;
	ContentVersion = 0;
	CurrentSaveVersion = 0;
	MinimumReadableSaveVersion = 0;
}

bool FBSCompatibility::TryParseVersion(const FString& Text, uint32& OutVersion)
{
	OutVersion = 0;

	if (Text.IsEmpty() || Text.Len() > 10 || Text[0] < TEXT('1') || Text[0] > TEXT('9'))
	{
		return false;
	}

	uint64 ParsedValue = 0;
	for (const TCHAR Character : Text)
	{
		if (Character < TEXT('0') || Character > TEXT('9'))
		{
			return false;
		}

		ParsedValue = (ParsedValue * 10) + static_cast<uint64>(Character - TEXT('0'));
		if (ParsedValue > MAX_uint32)
		{
			return false;
		}
	}

	OutVersion = static_cast<uint32>(ParsedValue);
	return true;
}

bool FBSCompatibility::TryLoadCurrentPolicy(FBSCompatibilityPolicy& OutPolicy)
{
	OutPolicy.Reset();

	uint32 BuildVersion = 0;
	uint32 ContentVersion = 0;
	uint32 CurrentSaveVersion = 0;
	uint32 MinimumReadableSaveVersion = 0;

	if (!TryLoadVersion(BuildVersionKey, BuildVersion)
		|| !TryLoadVersion(ContentVersionKey, ContentVersion)
		|| !TryLoadVersion(CurrentSaveVersionKey, CurrentSaveVersion)
		|| !TryLoadVersion(MinimumReadableSaveVersionKey, MinimumReadableSaveVersion))
	{
		return false;
	}

	return FBSCompatibilityPolicy::TryCreate(
		BuildVersion,
		ContentVersion,
		CurrentSaveVersion,
		MinimumReadableSaveVersion,
		OutPolicy);
}

EBSCompatibilityResult FBSCompatibility::Evaluate(
	const FBSCompatibilityPolicy& Policy,
	const FBSCompatibilitySignature& Signature)
{
	if (!Policy.IsValid())
	{
		return EBSCompatibilityResult::InvalidPolicy;
	}

	if (!Signature.IsValid())
	{
		return EBSCompatibilityResult::InvalidSignature;
	}

	if (Signature.GetBuildCompatibilityVersion() != Policy.GetBuildCompatibilityVersion())
	{
		return EBSCompatibilityResult::BuildVersionMismatch;
	}

	if (Signature.GetContentCompatibilityVersion() != Policy.GetContentCompatibilityVersion())
	{
		return EBSCompatibilityResult::ContentVersionMismatch;
	}

	if (Signature.GetSaveSchemaVersion() < Policy.GetMinimumReadableSaveSchemaVersion())
	{
		return EBSCompatibilityResult::SaveSchemaTooOld;
	}

	if (Signature.GetSaveSchemaVersion() > Policy.GetCurrentSaveSchemaVersion())
	{
		return EBSCompatibilityResult::SaveSchemaTooNew;
	}

	return EBSCompatibilityResult::Compatible;
}

const TCHAR* FBSCompatibility::GetStableName(const EBSCompatibilityResult Result)
{
	switch (Result)
	{
	case EBSCompatibilityResult::Compatible:
		return TEXT("compatible");
	case EBSCompatibilityResult::InvalidPolicy:
		return TEXT("invalid_policy");
	case EBSCompatibilityResult::InvalidSignature:
		return TEXT("invalid_signature");
	case EBSCompatibilityResult::BuildVersionMismatch:
		return TEXT("build_version_mismatch");
	case EBSCompatibilityResult::ContentVersionMismatch:
		return TEXT("content_version_mismatch");
	case EBSCompatibilityResult::SaveSchemaTooOld:
		return TEXT("save_schema_too_old");
	case EBSCompatibilityResult::SaveSchemaTooNew:
		return TEXT("save_schema_too_new");
	default:
		return TEXT("unknown");
	}
}
