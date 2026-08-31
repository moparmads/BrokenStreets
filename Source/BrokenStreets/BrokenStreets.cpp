// Copyright Epic Games, Inc. All Rights Reserved.

#include "BrokenStreets.h"
#include "Core/Compatibility/BSCompatibility.h"
#if !UE_BUILD_SHIPPING
#include "Core/Debug/BSAuthorityStateDebug.h"
#endif
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

#if !UE_BUILD_SHIPPING
		AuthorityStateDebugOverlay = MakeUnique<FBSAuthorityStateDebugOverlay>();
		AuthorityStateDebugOverlay->Start();
#endif

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

	virtual void ShutdownModule() override
	{
#if !UE_BUILD_SHIPPING
		if (AuthorityStateDebugOverlay.IsValid())
		{
			AuthorityStateDebugOverlay->Stop();
			AuthorityStateDebugOverlay.Reset();
		}
#endif

		FDefaultGameModuleImpl::ShutdownModule();
	}

private:
#if !UE_BUILD_SHIPPING
	TUniquePtr<FBSAuthorityStateDebugOverlay> AuthorityStateDebugOverlay;
#endif
};

IMPLEMENT_PRIMARY_GAME_MODULE(FBrokenStreetsModule, BrokenStreets, "BrokenStreets");
