// Copyright Epic Games, Inc. All Rights Reserved.

#include "BrokenStreets.h"
#include "Core/Compatibility/BSCompatibility.h"
#include "Core/FeatureFlags/BSFeatureFlags.h"
#include "Core/Observability/BSLogCategories.h"
#include "Core/Observability/BSLogContext.h"
#include "Modules/ModuleManager.h"

class FBrokenStreetsModule final : public FDefaultGameModuleImpl
{
public:
	virtual void StartupModule() override
	{
		FDefaultGameModuleImpl::StartupModule();

		FBSCompatibilityPolicy CompatibilityPolicy;
		if (!FBSCompatibility::TryLoadCurrentPolicy(CompatibilityPolicy))
		{
			FBSLogContext Context;
			if (FBSLogContext::TryCreate(TEXT("compatibility_startup"), Context))
			{
				UE_LOG(
					LogBSCore,
					Error,
					TEXT("Compatibility configuration is missing or invalid; future peer and profile acceptance must fail closed. %s"),
					*Context.ToLogString());
			}
		}

		if (!FBSFeatureFlags::IsEnabled(EBSFeatureFlag::CoreVerboseDiagnostics))
		{
			return;
		}

		FBSLogContext Context;
		if (FBSLogContext::TryCreate(TEXT("module_startup"), Context))
		{
			UE_LOG(LogBrokenStreets, Log, TEXT("Verbose Core diagnostics enabled. %s"), *Context.ToLogString());
		}
	}
};

IMPLEMENT_PRIMARY_GAME_MODULE(FBrokenStreetsModule, BrokenStreets, "BrokenStreets");
