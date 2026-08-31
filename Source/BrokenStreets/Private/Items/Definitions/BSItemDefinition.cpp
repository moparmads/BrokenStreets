// Copyright Madalin Gavrila. All Rights Reserved.

#include "Items/Definitions/BSItemDefinition.h"

#include "Misc/DataValidation.h"
#include "UObject/Package.h"

#define LOCTEXT_NAMESPACE "BSItemDefinition"

const FPrimaryAssetType UBSItemDefinition::ItemAssetType(TEXT("item"));
const FName UBSItemDefinition::WorldBundle(TEXT("World"));
const FName UBSItemDefinition::UIBundle(TEXT("UI"));

FPrimaryAssetId UBSItemDefinition::GetPrimaryAssetId() const
{
	const FPrimaryAssetId PrimaryAssetId = DefinitionId.ToPrimaryAssetId();
	return PrimaryAssetId.PrimaryAssetType == ItemAssetType ? PrimaryAssetId : FPrimaryAssetId();
}

#if WITH_EDITOR
EDataValidationResult UBSItemDefinition::IsDataValid(FDataValidationContext& Context) const
{
	EDataValidationResult Result = Super::IsDataValid(Context);

	if (!DefinitionId.IsValid())
	{
		Context.AddError(LOCTEXT("InvalidDefinitionId", "DefinitionId must use canonical item:<name> text."));
		Result = EDataValidationResult::Invalid;
	}
	else if (DefinitionId.ToPrimaryAssetId().PrimaryAssetType != ItemAssetType)
	{
		Context.AddError(LOCTEXT("WrongDefinitionType", "DefinitionId must use the item primary asset type."));
		Result = EDataValidationResult::Invalid;
	}

	if (!GetName().StartsWith(TEXT("DA_Item_"), ESearchCase::CaseSensitive))
	{
		Context.AddError(LOCTEXT("InvalidAssetName", "Item definition asset names must start with DA_Item_."));
		Result = EDataValidationResult::Invalid;
	}

	const FString PackageName = GetOutermost()->GetName();
	if (!PackageName.StartsWith(TEXT("/Game/BS/Definitions/Items/"), ESearchCase::CaseSensitive))
	{
		Context.AddError(LOCTEXT("InvalidAssetPath", "Item definitions must be stored below /Game/BS/Definitions/Items/."));
		Result = EDataValidationResult::Invalid;
	}

	return Result;
}
#endif

#undef LOCTEXT_NAMESPACE
