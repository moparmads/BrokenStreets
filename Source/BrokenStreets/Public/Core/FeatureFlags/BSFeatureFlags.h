// Copyright Madalin Gavrila. All Rights Reserved.

#pragma once

#include "CoreMinimal.h"

/** Closed set of reviewed Broken Streets rollout controls. */
enum class EBSFeatureFlag : uint8
{
	/** Enables one structured Core diagnostic during primary-module startup. */
	CoreVerboseDiagnostics,
};

/** Low-frequency, fail-closed access to project-owned feature-flag configuration. */
class BROKENSTREETS_API FBSFeatureFlags final
{
public:
	/** Returns false for missing, malformed, or unknown flags. Do not call from Tick or a hot loop. */
	[[nodiscard]] static bool IsEnabled(EBSFeatureFlag Flag);

	/** Stable diagnostic name, or nullptr for an unknown enum value. */
	[[nodiscard]] static const TCHAR* GetName(EBSFeatureFlag Flag);

	/** Project configuration key, or nullptr for an unknown enum value. */
	[[nodiscard]] static const TCHAR* GetConfigKey(EBSFeatureFlag Flag);

	/** Accepts only canonical Unreal INI booleans: True or False. Failure clears OutEnabled. */
	[[nodiscard]] static bool TryParseConfigValue(const FString& Value, bool& OutEnabled);
};
