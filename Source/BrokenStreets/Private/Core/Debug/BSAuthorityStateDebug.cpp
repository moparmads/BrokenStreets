// Copyright Madalin Gavrila. All Rights Reserved.

#include "Core/Debug/BSAuthorityStateDebug.h"

#if !UE_BUILD_SHIPPING

#include "Core/Observability/BSLogCategories.h"
#include "Debug/DebugDrawService.h"
#include "Engine/Canvas.h"
#include "Engine/Engine.h"
#include "Engine/World.h"
#include "GameFramework/Pawn.h"
#include "GameFramework/PlayerController.h"
#include "HAL/IConsoleManager.h"

namespace
{
constexpr TCHAR OverlayCommandName[] = TEXT("bs.Debug.AuthorityStateOverlay");
constexpr TCHAR MissingValue[] = TEXT("missing");

FString GetAuthorityName(const ENetRole Role)
{
	return Role == ROLE_Authority ? TEXT("authority") : TEXT("not_authority");
}
} // namespace

FBSAuthorityStateSnapshot FBSAuthorityStateSnapshot::Capture(const APlayerController* PlayerController)
{
	if (PlayerController == nullptr)
	{
		return FBSAuthorityStateSnapshot();
	}

	const UWorld* WorldObject = PlayerController->GetWorld();
	const APawn* Pawn = PlayerController->GetPawn();
	return Create(
		WorldObject != nullptr && WorldObject->GetOutermost() != nullptr
			? WorldObject->GetOutermost()->GetName()
			: FString(MissingValue),
		WorldObject != nullptr ? WorldObject->GetNetMode() : NM_MAX,
		PlayerController->GetUniqueID(),
		PlayerController->GetLocalRole(),
		PlayerController->GetRemoteRole(),
		PlayerController->GetStateName().ToString(),
		Pawn != nullptr ? Pawn->GetUniqueID() : 0,
		Pawn != nullptr ? Pawn->GetLocalRole() : ROLE_None,
		Pawn != nullptr ? Pawn->GetRemoteRole() : ROLE_None);
}

FBSAuthorityStateSnapshot FBSAuthorityStateSnapshot::Create(
	const FString& InWorld,
	const ENetMode InNetMode,
	const uint32 InControllerObjectId,
	const ENetRole InControllerLocalRole,
	const ENetRole InControllerRemoteRole,
	const FString& InControllerState,
	const uint32 InPawnObjectId,
	const ENetRole InPawnLocalRole,
	const ENetRole InPawnRemoteRole)
{
	FBSAuthorityStateSnapshot Snapshot;
	Snapshot.World = NormalizeLabel(InWorld);
	Snapshot.NetMode = InNetMode;
	Snapshot.ControllerObjectId = InControllerObjectId;
	Snapshot.ControllerLocalRole = InControllerLocalRole;
	Snapshot.ControllerRemoteRole = InControllerRemoteRole;
	Snapshot.ControllerState = InControllerObjectId == 0 ? MissingValue : NormalizeLabel(InControllerState);
	Snapshot.PawnObjectId = InPawnObjectId;
	Snapshot.PawnLocalRole = InPawnLocalRole;
	Snapshot.PawnRemoteRole = InPawnRemoteRole;
	return Snapshot;
}

const TCHAR* FBSAuthorityStateSnapshot::GetNetModeName(const ENetMode InNetMode)
{
	switch (InNetMode)
	{
	case NM_Standalone:
		return TEXT("standalone");
	case NM_DedicatedServer:
		return TEXT("dedicated_server");
	case NM_ListenServer:
		return TEXT("listen_server");
	case NM_Client:
		return TEXT("client");
	default:
		return TEXT("invalid");
	}
}

const TCHAR* FBSAuthorityStateSnapshot::GetRoleName(const ENetRole Role)
{
	switch (Role)
	{
	case ROLE_None:
		return TEXT("none");
	case ROLE_SimulatedProxy:
		return TEXT("simulated_proxy");
	case ROLE_AutonomousProxy:
		return TEXT("autonomous_proxy");
	case ROLE_Authority:
		return TEXT("authority");
	default:
		return TEXT("invalid");
	}
}

FString FBSAuthorityStateSnapshot::ToLogString() const
{
	FString Result = FString::Printf(
		TEXT("owner=player_controller authority=%s object_id=%u state=%s net_mode=%s"),
		*GetAuthorityName(ControllerLocalRole),
		ControllerObjectId,
		*ControllerState,
		GetNetModeName(NetMode));

	if (Result.Len() > MaxFormattedLength)
	{
		Result.LeftInline(MaxFormattedLength, EAllowShrinking::No);
	}
	return Result;
}

void FBSAuthorityStateSnapshot::BuildOverlayLines(TArray<FString>& OutLines) const
{
	OutLines.Reset(4);
	OutLines.Add(TEXT("BROKEN STREETS — AUTHORITY / STATE"));
	OutLines.Add(FString::Printf(TEXT("world=%s net_mode=%s"), *World, GetNetModeName(NetMode)));
	OutLines.Add(FString::Printf(
		TEXT("owner=player_controller object_id=%u local_role=%s remote_role=%s state=%s"),
		ControllerObjectId,
		GetRoleName(ControllerLocalRole),
		GetRoleName(ControllerRemoteRole),
		*ControllerState));
	OutLines.Add(FString::Printf(
		TEXT("owner=pawn object_id=%u local_role=%s remote_role=%s"),
		PawnObjectId,
		GetRoleName(PawnLocalRole),
		GetRoleName(PawnRemoteRole)));

	for (FString& Line : OutLines)
	{
		if (Line.Len() > MaxFormattedLength)
		{
			Line.LeftInline(MaxFormattedLength, EAllowShrinking::No);
		}
	}
}

FString FBSAuthorityStateSnapshot::NormalizeLabel(const FString& Value)
{
	if (Value.IsEmpty())
	{
		return MissingValue;
	}

	FString Result;
	Result.Reserve(FMath::Min(Value.Len(), MaxLabelLength));
	for (const TCHAR Character : Value)
	{
		if (Result.Len() >= MaxLabelLength)
		{
			break;
		}

		if (Character >= TEXT('A') && Character <= TEXT('Z'))
		{
			Result.AppendChar(Character - TEXT('A') + TEXT('a'));
		}
		else if ((Character >= TEXT('a') && Character <= TEXT('z'))
			|| (Character >= TEXT('0') && Character <= TEXT('9'))
			|| Character == TEXT('_')
			|| Character == TEXT('-')
			|| Character == TEXT('.')
			|| Character == TEXT('/')
			|| Character == TEXT(':'))
		{
			Result.AppendChar(Character);
		}
		else
		{
			Result.AppendChar(TEXT('_'));
		}
	}

	return Result.IsEmpty() ? FString(MissingValue) : Result;
}

void FBSAuthorityStateDebugOverlay::Start()
{
	if (ConsoleVariable != nullptr)
	{
		return;
	}

	ConsoleVariable = IConsoleManager::Get().RegisterConsoleVariable(
		OverlayCommandName,
		false,
		TEXT("Draw the local Broken Streets authority/state overlay. 0: disabled, 1: enabled."),
		ECVF_Cheat);
	ConsoleVariable->SetOnChangedCallback(
		FConsoleVariableDelegate::CreateRaw(this, &FBSAuthorityStateDebugOverlay::HandleSettingChanged));
}

void FBSAuthorityStateDebugOverlay::Stop()
{
	UnregisterDrawDelegate();
	if (ConsoleVariable != nullptr)
	{
		ConsoleVariable->SetOnChangedCallback(FConsoleVariableDelegate());
		IConsoleManager::Get().UnregisterConsoleObject(OverlayCommandName, false);
		ConsoleVariable = nullptr;
	}

	bHasLastSnapshot = false;
	bLogNextSnapshot = false;
}

void FBSAuthorityStateDebugOverlay::HandleSettingChanged(IConsoleVariable* Variable)
{
	const bool bEnabled = Variable != nullptr && Variable->GetBool();
	if (bEnabled)
	{
		RegisterDrawDelegate();
		bLogNextSnapshot = true;
		return;
	}

	UnregisterDrawDelegate();
	const FString Context = bHasLastSnapshot
		? LastSnapshot.ToLogString()
		: FString(TEXT("owner=player_controller authority=not_authority object_id=0 state=missing net_mode=invalid"));
	UE_LOG(LogBSCore, Display, TEXT("Authority/state overlay disabled. %s overlay=disabled"), *Context);
	bHasLastSnapshot = false;
	bLogNextSnapshot = false;
}

void FBSAuthorityStateDebugOverlay::Draw(UCanvas* Canvas, APlayerController* PlayerController)
{
	if (Canvas == nullptr || GEngine == nullptr)
	{
		return;
	}

	const FBSAuthorityStateSnapshot Snapshot = FBSAuthorityStateSnapshot::Capture(PlayerController);
	if (bLogNextSnapshot)
	{
		UE_LOG(LogBSCore, Display, TEXT("Authority/state overlay enabled. %s overlay=enabled"), *Snapshot.ToLogString());
		bLogNextSnapshot = false;
	}

	LastSnapshot = Snapshot;
	bHasLastSnapshot = true;

	TArray<FString> Lines;
	Snapshot.BuildOverlayLines(Lines);
	const FVector2D Origin(24.0, 48.0);
	for (int32 Index = 0; Index < Lines.Num(); ++Index)
	{
		Canvas->K2_DrawText(
			GEngine->GetSmallFont(),
			Lines[Index],
			Origin + FVector2D(0.0, Index * 18.0),
			FVector2D(1.0, 1.0),
			Index == 0 ? FLinearColor(1.0f, 0.75f, 0.1f) : FLinearColor::White,
			0.0,
			FLinearColor::Black,
			FVector2D(1.0, 1.0),
			false,
			false,
			true,
			FLinearColor::Black);
	}
}

void FBSAuthorityStateDebugOverlay::RegisterDrawDelegate()
{
	if (!DrawDelegateHandle.IsValid())
	{
		DrawDelegateHandle = UDebugDrawService::Register(
			TEXT("Game"),
			FDebugDrawDelegate::CreateRaw(this, &FBSAuthorityStateDebugOverlay::Draw));
	}
}

void FBSAuthorityStateDebugOverlay::UnregisterDrawDelegate()
{
	if (DrawDelegateHandle.IsValid())
	{
		UDebugDrawService::Unregister(DrawDelegateHandle);
		DrawDelegateHandle.Reset();
	}
}

#endif // !UE_BUILD_SHIPPING
