// Copyright Epic Games, Inc. All Rights Reserved.

#if WITH_DEV_AUTOMATION_TESTS

#include "Misc/App.h"
#include "Misc/AutomationTest.h"
#include "Modules/ModuleManager.h"

IMPLEMENT_SIMPLE_AUTOMATION_TEST(
	FBrokenStreetsProjectBootSmokeTest,
	"BrokenStreets.Smoke.ProjectBoot",
	EAutomationTestFlags::EditorContext | EAutomationTestFlags::EngineFilter)

bool FBrokenStreetsProjectBootSmokeTest::RunTest(const FString& Parameters)
{
	const FString ProjectName(FApp::GetProjectName());
	const bool bProjectNameMatches = TestEqual(
		TEXT("The running project has the canonical Broken Streets name"),
		ProjectName,
		FString(TEXT("BrokenStreets")));
	const bool bPrimaryModuleLoaded = TestTrue(
		TEXT("The BrokenStreets primary game module is loaded"),
		FModuleManager::Get().IsModuleLoaded(TEXT("BrokenStreets")));

	return bProjectNameMatches && bPrimaryModuleLoaded;
}

#endif // WITH_DEV_AUTOMATION_TESTS
