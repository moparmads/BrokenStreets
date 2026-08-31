// Copyright Madalin Gavrila. All Rights Reserved.

#include "Core/Results/BSResult.h"

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

bool IsValidErrorSegment(const FString& Segment)
{
	if (Segment.IsEmpty()
		|| Segment.Len() > FBSErrorCode::MaxSegmentLength
		|| !IsLowerAsciiLetter(Segment[0]))
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

bool IsValidErrorCodeText(const FString& Text)
{
	int32 SeparatorIndex = INDEX_NONE;
	if (!Text.FindChar(TEXT('.'), SeparatorIndex))
	{
		return false;
	}

	if (Text.Find(TEXT("."), ESearchCase::CaseSensitive, ESearchDir::FromStart, SeparatorIndex + 1) != INDEX_NONE)
	{
		return false;
	}

	return IsValidErrorSegment(Text.Left(SeparatorIndex))
		&& IsValidErrorSegment(Text.Mid(SeparatorIndex + 1));
}
} // namespace

bool FBSErrorCode::TryParse(const FString& Text, FBSErrorCode& OutCode)
{
	OutCode.Reset();

	if (!IsValidErrorCodeText(Text))
	{
		return false;
	}

	OutCode.CanonicalValue = Text;
	return true;
}

bool FBSErrorCode::IsValid() const
{
	return IsValidErrorCodeText(CanonicalValue);
}

FString FBSErrorCode::ToString() const
{
	return IsValid() ? CanonicalValue : FString();
}

void FBSErrorCode::Reset()
{
	CanonicalValue.Reset();
}

FBSResult FBSResult::Succeeded()
{
	FBSResult Result;
	Result.StatusValue = EBSResultStatus::Succeeded;
	return Result;
}

bool FBSResult::TryCreateRejected(const FBSErrorCode& ErrorCode, FBSResult& OutResult)
{
	return TryCreateWithError(EBSResultStatus::Rejected, ErrorCode, OutResult);
}

bool FBSResult::TryCreateFailed(const FBSErrorCode& ErrorCode, FBSResult& OutResult)
{
	return TryCreateWithError(EBSResultStatus::Failed, ErrorCode, OutResult);
}

bool FBSResult::IsValid() const
{
	if (StatusValue == EBSResultStatus::Succeeded)
	{
		return !ErrorCodeValue.IsValid();
	}

	if (StatusValue == EBSResultStatus::Rejected || StatusValue == EBSResultStatus::Failed)
	{
		return ErrorCodeValue.IsValid();
	}

	return false;
}

bool FBSResult::IsSucceeded() const
{
	return IsValid() && StatusValue == EBSResultStatus::Succeeded;
}

bool FBSResult::IsRejected() const
{
	return IsValid() && StatusValue == EBSResultStatus::Rejected;
}

bool FBSResult::IsFailed() const
{
	return IsValid() && StatusValue == EBSResultStatus::Failed;
}

EBSResultStatus FBSResult::GetStatus() const
{
	return StatusValue;
}

const FBSErrorCode& FBSResult::GetErrorCode() const
{
	return ErrorCodeValue;
}

const TCHAR* FBSResult::GetStableName(const EBSResultStatus Status)
{
	switch (Status)
	{
	case EBSResultStatus::Invalid:
		return TEXT("invalid");
	case EBSResultStatus::Succeeded:
		return TEXT("succeeded");
	case EBSResultStatus::Rejected:
		return TEXT("rejected");
	case EBSResultStatus::Failed:
		return TEXT("failed");
	default:
		return TEXT("unknown");
	}
}

void FBSResult::Reset()
{
	StatusValue = EBSResultStatus::Invalid;
	ErrorCodeValue.Reset();
}

bool FBSResult::TryCreateWithError(
	const EBSResultStatus Status,
	const FBSErrorCode& ErrorCode,
	FBSResult& OutResult)
{
	OutResult.Reset();

	if ((Status != EBSResultStatus::Rejected && Status != EBSResultStatus::Failed)
		|| !ErrorCode.IsValid())
	{
		return false;
	}

	OutResult.StatusValue = Status;
	OutResult.ErrorCodeValue = ErrorCode;
	return true;
}
