// Copyright Madalin Gavrila. All Rights Reserved.

#if WITH_DEV_AUTOMATION_TESTS && !UE_BUILD_SHIPPING

#include "Core/Debug/BSAuthorityStateDebug.h"
#include "Misc/AutomationTest.h"

IMPLEMENT_SIMPLE_AUTOMATION_TEST(
	FBrokenStreetsAuthorityStateNamesTest,
	"BrokenStreets.Core.Debug.AuthorityState.Names",
	EAutomationTestFlags::EditorContext | EAutomationTestFlags::EngineFilter)

bool FBrokenStreetsAuthorityStateNamesTest::RunTest(const FString& Parameters)
{
	bool bPassed = true;
	bPassed &= TestEqual(TEXT("Standalone has a stable name"), FString(FBSAuthorityStateSnapshot::GetNetModeName(NM_Standalone)), FString(TEXT("standalone")));
	bPassed &= TestEqual(TEXT("Dedicated server has a stable name"), FString(FBSAuthorityStateSnapshot::GetNetModeName(NM_DedicatedServer)), FString(TEXT("dedicated_server")));
	bPassed &= TestEqual(TEXT("Listen server has a stable name"), FString(FBSAuthorityStateSnapshot::GetNetModeName(NM_ListenServer)), FString(TEXT("listen_server")));
	bPassed &= TestEqual(TEXT("Client has a stable name"), FString(FBSAuthorityStateSnapshot::GetNetModeName(NM_Client)), FString(TEXT("client")));
	bPassed &= TestEqual(TEXT("An unknown net mode fails to invalid"), FString(FBSAuthorityStateSnapshot::GetNetModeName(static_cast<ENetMode>(255))), FString(TEXT("invalid")));

	bPassed &= TestEqual(TEXT("No role has a stable name"), FString(FBSAuthorityStateSnapshot::GetRoleName(ROLE_None)), FString(TEXT("none")));
	bPassed &= TestEqual(TEXT("Simulated proxy has a stable name"), FString(FBSAuthorityStateSnapshot::GetRoleName(ROLE_SimulatedProxy)), FString(TEXT("simulated_proxy")));
	bPassed &= TestEqual(TEXT("Autonomous proxy has a stable name"), FString(FBSAuthorityStateSnapshot::GetRoleName(ROLE_AutonomousProxy)), FString(TEXT("autonomous_proxy")));
	bPassed &= TestEqual(TEXT("Authority has a stable name"), FString(FBSAuthorityStateSnapshot::GetRoleName(ROLE_Authority)), FString(TEXT("authority")));
	bPassed &= TestEqual(TEXT("An unknown role fails to invalid"), FString(FBSAuthorityStateSnapshot::GetRoleName(static_cast<ENetRole>(255))), FString(TEXT("invalid")));
	return bPassed;
}

IMPLEMENT_SIMPLE_AUTOMATION_TEST(
	FBrokenStreetsAuthorityStateSnapshotTest,
	"BrokenStreets.Core.Debug.AuthorityState.Snapshot",
	EAutomationTestFlags::EditorContext | EAutomationTestFlags::EngineFilter)

bool FBrokenStreetsAuthorityStateSnapshotTest::RunTest(const FString& Parameters)
{
	bool bPassed = true;
	const FBSAuthorityStateSnapshot Snapshot = FBSAuthorityStateSnapshot::Create(
		TEXT("/Game/BS/Maps/Test/L_TestGym_Network"),
		NM_ListenServer,
		101,
		ROLE_Authority,
		ROLE_AutonomousProxy,
		TEXT("Playing"),
		202,
		ROLE_Authority,
		ROLE_SimulatedProxy);

	bPassed &= TestEqual(TEXT("World text is normalized"), Snapshot.World, FString(TEXT("/game/bs/maps/test/l_testgym_network")));
	bPassed &= TestEqual(TEXT("Controller state is normalized"), Snapshot.ControllerState, FString(TEXT("playing")));
	bPassed &= TestEqual(
		TEXT("The structured log has exact owner, authority, ID, state, and net mode order"),
		Snapshot.ToLogString(),
		FString(TEXT("owner=player_controller authority=authority object_id=101 state=playing net_mode=listen_server")));

	TArray<FString> Lines;
	Snapshot.BuildOverlayLines(Lines);
	bPassed &= TestEqual(TEXT("The overlay has a bounded fixed row count"), Lines.Num(), 4);
	bPassed &= TestEqual(TEXT("The overlay title is explicit"), Lines[0], FString(TEXT("BROKEN STREETS — AUTHORITY / STATE")));
	bPassed &= TestEqual(TEXT("The world and net mode row is deterministic"), Lines[1], FString(TEXT("world=/game/bs/maps/test/l_testgym_network net_mode=listen_server")));
	bPassed &= TestEqual(TEXT("The controller row is deterministic"), Lines[2], FString(TEXT("owner=player_controller object_id=101 local_role=authority remote_role=autonomous_proxy state=playing")));
	bPassed &= TestEqual(TEXT("The pawn row is deterministic"), Lines[3], FString(TEXT("owner=pawn object_id=202 local_role=authority remote_role=simulated_proxy")));
	for (const FString& Line : Lines)
	{
		bPassed &= TestTrue(TEXT("Every overlay row stays within the fixed bound"), Line.Len() <= FBSAuthorityStateSnapshot::MaxFormattedLength);
	}

	const FString UntrustedLabel = FString::ChrN(FBSAuthorityStateSnapshot::MaxLabelLength + 20, TEXT('A')) + TEXT("\nprivate value");
	const FBSAuthorityStateSnapshot Bounded = FBSAuthorityStateSnapshot::Create(
		UntrustedLabel,
		static_cast<ENetMode>(255),
		0,
		static_cast<ENetRole>(255),
		static_cast<ENetRole>(255),
		TEXT("Should Not Survive"),
		0,
		ROLE_None,
		ROLE_None);
	bPassed &= TestEqual(TEXT("Untrusted world text is clipped"), Bounded.World.Len(), FBSAuthorityStateSnapshot::MaxLabelLength);
	bPassed &= TestFalse(TEXT("Untrusted world text cannot contain a newline"), Bounded.World.Contains(TEXT("\n")));
	bPassed &= TestEqual(TEXT("A missing controller clears state"), Bounded.ControllerState, FString(TEXT("missing")));
	bPassed &= TestEqual(
		TEXT("Unknown and missing values fail closed"),
		Bounded.ToLogString(),
		FString(TEXT("owner=player_controller authority=not_authority object_id=0 state=missing net_mode=invalid")));

	return bPassed;
}

#endif // WITH_DEV_AUTOMATION_TESTS && !UE_BUILD_SHIPPING
