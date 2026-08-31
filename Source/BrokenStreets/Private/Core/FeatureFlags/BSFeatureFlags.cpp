// Copyright Madalin Gavrila. All Rights Reserved.

#include "Core/FeatureFlags/BSFeatureFlags.h"

#include "Core/Observability/BSLogCategories.h"
#include "Core/Observability/BSLogContext.h"
#include "Misc/ConfigCacheIni.h"

namespace
{
constexpr TCHAR FeatureFlagSection[] = TEXT("BrokenStreets.FeatureFlags");
constexpr TCHAR CoreVerboseDiagnosticsName[] = TEXT("core_verbose_diagnostics");
constexpr TCHAR CoreVerboseDiagnosticsKey[] = TEXT("CoreVerboseDiagnostics");
} // namespace

bool FBSFeatureFlags::IsEnabled(const EBSFeatureFlag Flag)
{
	const TCHAR* ConfigKey = GetConfigKey(Flag);
	if (ConfigKey == nullptr || GConfig == nullptr)
	{
		return false;
	}

	FString ConfigValue;
	if (!GConfig->GetString(FeatureFlagSection, ConfigKey, ConfigValue, GGameIni))
	{
		return false;
	}

	bool bEnabled = false;
	if (TryParseConfigValue(ConfigValue, bEnabled))
	{
		return bEnabled;
	}

	FBSLogContext Context;
	if (FBSLogContext::TryCreate(TEXT("feature_flag_read"), Context))
	{
		UE_LOG(
			LogBSCore,
			Warning,
			TEXT("Feature flag '%s' must be True or False and was disabled. %s"),
			GetName(Flag),
			*Context.ToLogString());
	}

	return false;
}

const TCHAR* FBSFeatureFlags::GetName(const EBSFeatureFlag Flag)
{
	switch (Flag)
	{
	case EBSFeatureFlag::CoreVerboseDiagnostics:
		return CoreVerboseDiagnosticsName;
	default:
		return nullptr;
	}
}

const TCHAR* FBSFeatureFlags::GetConfigKey(const EBSFeatureFlag Flag)
{
	switch (Flag)
	{
	case EBSFeatureFlag::CoreVerboseDiagnostics:
		return CoreVerboseDiagnosticsKey;
	default:
		return nullptr;
	}
}

bool FBSFeatureFlags::TryParseConfigValue(const FString& Value, bool& OutEnabled)
{
	OutEnabled = false;

	if (Value.Equals(TEXT("True"), ESearchCase::CaseSensitive))
	{
		OutEnabled = true;
		return true;
	}

	return Value.Equals(TEXT("False"), ESearchCase::CaseSensitive);
}
