// Copyright Madalin Gavrila. All Rights Reserved.

#pragma once

#include "CoreMinimal.h"
#include "Core/Identity/BSIdentifiers.h"
#include "Engine/DataAsset.h"

#include "BSItemDefinition.generated.h"

class UStaticMesh;
class UTexture2D;

/** Stable, data-only definition for one item catalog entry. */
UCLASS(BlueprintType)
class BROKENSTREETS_API UBSItemDefinition final : public UPrimaryDataAsset
{
	GENERATED_BODY()

public:
	static const FPrimaryAssetType ItemAssetType;
	static const FName WorldBundle;
	static const FName UIBundle;

	virtual FPrimaryAssetId GetPrimaryAssetId() const override;

#if WITH_EDITOR
	virtual EDataValidationResult IsDataValid(FDataValidationContext& Context) const override;
#endif

	/** Stable identity; it is independent of the asset package name and path. */
	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Broken Streets|Items")
	FBSDefinitionId DefinitionId;

	/** Optional world representation, loaded only when the World bundle is requested. */
	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Broken Streets|Items", meta = (AssetBundles = "World"))
	TSoftObjectPtr<UStaticMesh> WorldMesh;

	/** Optional interface representation, loaded only when the UI bundle is requested. */
	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Broken Streets|Items", meta = (AssetBundles = "UI"))
	TSoftObjectPtr<UTexture2D> Icon;
};
