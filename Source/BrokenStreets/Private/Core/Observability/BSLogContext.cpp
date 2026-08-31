// Copyright Madalin Gavrila. All Rights Reserved.

#include "Core/Observability/BSLogContext.h"

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

bool IsValidOperation(const FString& Operation)
{
	if (Operation.IsEmpty()
		|| Operation.Len() > FBSLogContext::MaxOperationLength
		|| !IsLowerAsciiLetter(Operation[0]))
	{
		return false;
	}

	for (const TCHAR Character : Operation)
	{
		if (!IsLowerAsciiLetter(Character) && !IsAsciiDigit(Character) && Character != TEXT('_'))
		{
			return false;
		}
	}

	return true;
}
} // namespace

bool FBSLogContext::TryCreate(const FString& Operation, FBSLogContext& OutContext)
{
	OutContext.Reset();

	if (!IsValidOperation(Operation))
	{
		return false;
	}

	OutContext.OperationValue = Operation;
	return true;
}

bool FBSLogContext::TrySetDefinitionId(const FBSDefinitionId& InDefinitionId)
{
	DefinitionId.Reset();
	if (!InDefinitionId.IsValid())
	{
		return false;
	}

	DefinitionId = InDefinitionId;
	return true;
}

bool FBSLogContext::TrySetInstanceId(const FBSInstanceId& InInstanceId)
{
	InstanceId.Reset();
	if (!InInstanceId.IsValid())
	{
		return false;
	}

	InstanceId = InInstanceId;
	return true;
}

bool FBSLogContext::IsValid() const
{
	return IsValidOperation(OperationValue);
}

bool FBSLogContext::HasDefinitionId() const
{
	return DefinitionId.IsValid();
}

bool FBSLogContext::HasInstanceId() const
{
	return InstanceId.IsValid();
}

const FString& FBSLogContext::GetOperation() const
{
	return OperationValue;
}

FString FBSLogContext::ToLogString() const
{
	if (!IsValid())
	{
		return FString();
	}

	FString Result = FString::Printf(TEXT("operation=%s"), *OperationValue);
	if (DefinitionId.IsValid())
	{
		Result += FString::Printf(TEXT(" definition_id=%s"), *DefinitionId.ToString());
	}
	if (InstanceId.IsValid())
	{
		Result += FString::Printf(TEXT(" instance_id=%s"), *InstanceId.ToString());
	}

	return Result;
}

void FBSLogContext::Reset()
{
	OperationValue.Reset();
	DefinitionId.Reset();
	InstanceId.Reset();
}
