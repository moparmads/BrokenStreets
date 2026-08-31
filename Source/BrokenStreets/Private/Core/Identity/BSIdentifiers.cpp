// Copyright Madalin Gavrila. All Rights Reserved.

#include "Core/Identity/BSIdentifiers.h"

namespace
{
bool IsLowerAsciiLetter(const TCHAR Character)
{
	return Character >= TEXT('a') && Character <= TEXT('z');
}

bool IsAsciiDigit(const TCHAR Character)
{
	return Character >= TEXT('0') && Character <= TEXT('9');
}

bool IsValidDefinitionSegment(const FString& Segment)
{
	if (Segment.IsEmpty() || Segment.Len() > FBSDefinitionId::MaxSegmentLength || !IsLowerAsciiLetter(Segment[0]))
	{
		return false;
	}

	for (const TCHAR Character : Segment)
	{
		if (!IsLowerAsciiLetter(Character) && !IsAsciiDigit(Character) && Character != TEXT('_'))
		{
			return false;
		}
	}

	return true;
}

bool IsValidDefinitionText(const FString& Text)
{
	int32 SeparatorIndex = INDEX_NONE;
	if (!Text.FindChar(TEXT(':'), SeparatorIndex))
	{
		return false;
	}

	if (Text.Find(TEXT(":"), ESearchCase::CaseSensitive, ESearchDir::FromStart, SeparatorIndex + 1) != INDEX_NONE)
	{
		return false;
	}

	return IsValidDefinitionSegment(Text.Left(SeparatorIndex))
		&& IsValidDefinitionSegment(Text.Mid(SeparatorIndex + 1));
}
} // namespace

bool FBSDefinitionId::TryParse(const FString& Text, FBSDefinitionId& OutId)
{
	OutId.Reset();

	if (!IsValidDefinitionText(Text))
	{
		return false;
	}

	OutId.CanonicalValue = Text;
	return true;
}

bool FBSDefinitionId::IsValid() const
{
	return IsValidDefinitionText(CanonicalValue);
}

FString FBSDefinitionId::ToString() const
{
	return IsValid() ? CanonicalValue : FString();
}

FPrimaryAssetId FBSDefinitionId::ToPrimaryAssetId() const
{
	return IsValid() ? FPrimaryAssetId::ParseTypeAndName(CanonicalValue) : FPrimaryAssetId();
}

void FBSDefinitionId::Reset()
{
	CanonicalValue.Reset();
}

FBSInstanceId FBSInstanceId::Create()
{
	FBSInstanceId Result;
	do
	{
		Result.Value = FGuid::NewGuid();
	}
	while (!Result.Value.IsValid());

	return Result;
}

bool FBSInstanceId::TryParse(const FString& Text, FBSInstanceId& OutId)
{
	OutId.Reset();

	FGuid ParsedValue;
	if (!FGuid::ParseExact(Text, EGuidFormats::DigitsWithHyphensLower, ParsedValue)
		|| !ParsedValue.IsValid()
		|| !ParsedValue.ToString(EGuidFormats::DigitsWithHyphensLower).Equals(Text, ESearchCase::CaseSensitive))
	{
		return false;
	}

	OutId.Value = ParsedValue;
	return true;
}

bool FBSInstanceId::IsValid() const
{
	return Value.IsValid();
}

FString FBSInstanceId::ToString() const
{
	return IsValid() ? Value.ToString(EGuidFormats::DigitsWithHyphensLower) : FString();
}

const FGuid& FBSInstanceId::GetGuid() const
{
	return Value;
}

void FBSInstanceId::Reset()
{
	Value.Invalidate();
}
