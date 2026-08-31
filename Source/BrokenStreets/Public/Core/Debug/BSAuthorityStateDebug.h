// Copyright Madalin Gavrila. All Rights Reserved.

#pragma once

#include "CoreMinimal.h"

#if !UE_BUILD_SHIPPING

#include "Engine/EngineBaseTypes.h"
#include "Engine/EngineTypes.h"

class APlayerController;
class IConsoleVariable;
class UCanvas;

/** Bounded, read-only local authority data for the Development debug overlay. */
struct BROKENSTREETS_API FBSAuthorityStateSnapshot
{
	static constexpr int32 MaxLabelLength = 96;
	static constexpr int32 MaxFormattedLength = 512;

	FString World = TEXT("missing");
	ENetMode NetMode = NM_MAX;
	uint32 ControllerObjectId = 0;
	ENetRole ControllerLocalRole = ROLE_None;
	ENetRole ControllerRemoteRole = ROLE_None;
	FString ControllerState = TEXT("missing");
	uint32 PawnObjectId = 0;
	ENetRole PawnLocalRole = ROLE_None;
	ENetRole PawnRemoteRole = ROLE_None;

	/** Captures only the supplied local controller and its current pawn. */
	[[nodiscard]] static FBSAuthorityStateSnapshot Capture(const APlayerController* PlayerController);

	/** Creates a normalized snapshot without a World or Actor dependency for deterministic tests. */
	[[nodiscard]] static FBSAuthorityStateSnapshot Create(
		const FString& World,
		ENetMode NetMode,
		uint32 ControllerObjectId,
		ENetRole ControllerLocalRole,
		ENetRole ControllerRemoteRole,
		const FString& ControllerState,
		uint32 PawnObjectId,
		ENetRole PawnLocalRole,
		ENetRole PawnRemoteRole);

	[[nodiscard]] static const TCHAR* GetNetModeName(ENetMode NetMode);
	[[nodiscard]] static const TCHAR* GetRoleName(ENetRole Role);
	[[nodiscard]] FString ToLogString() const;
	void BuildOverlayLines(TArray<FString>& OutLines) const;

private:
	[[nodiscard]] static FString NormalizeLabel(const FString& Value);
};

/** Registers the non-Shipping console control and the draw callback only while enabled. */
class BROKENSTREETS_API FBSAuthorityStateDebugOverlay final
{
public:
	void Start();
	void Stop();

private:
	void HandleSettingChanged(IConsoleVariable* Variable);
	void Draw(UCanvas* Canvas, APlayerController* PlayerController);
	void RegisterDrawDelegate();
	void UnregisterDrawDelegate();

	IConsoleVariable* ConsoleVariable = nullptr;
	FDelegateHandle DrawDelegateHandle;
	FBSAuthorityStateSnapshot LastSnapshot;
	bool bHasLastSnapshot = false;
	bool bLogNextSnapshot = false;
};

#endif // !UE_BUILD_SHIPPING
