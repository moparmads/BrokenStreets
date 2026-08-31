// Copyright Madalin Gavrila. All Rights Reserved.

#include "Core/Commands/BSCommandEnvelope.h"

namespace
{
bool TryParseCanonicalGuid(const FString& Text, FGuid& OutValue)
{
	OutValue.Invalidate();

	FGuid ParsedValue;
	if (!FGuid::ParseExact(Text, EGuidFormats::DigitsWithHyphensLower, ParsedValue)
		|| !ParsedValue.IsValid()
		|| !ParsedValue.ToString(EGuidFormats::DigitsWithHyphensLower).Equals(Text, ESearchCase::CaseSensitive))
	{
		return false;
	}

	OutValue = ParsedValue;
	return true;
}

FGuid CreateNonZeroGuid()
{
	FGuid Result;
	do
	{
		Result = FGuid::NewGuid();
	}
	while (!Result.IsValid());

	return Result;
}
} // namespace

FBSCommandId FBSCommandId::Create()
{
	FBSCommandId Result;
	Result.Value = CreateNonZeroGuid();
	return Result;
}

bool FBSCommandId::TryParse(const FString& Text, FBSCommandId& OutId)
{
	OutId.Reset();
	return TryParseCanonicalGuid(Text, OutId.Value);
}

bool FBSCommandId::IsValid() const
{
	return Value.IsValid();
}

FString FBSCommandId::ToString() const
{
	return IsValid() ? Value.ToString(EGuidFormats::DigitsWithHyphensLower) : FString();
}

const FGuid& FBSCommandId::GetGuid() const
{
	return Value;
}

void FBSCommandId::Reset()
{
	Value.Invalidate();
}

FBSCorrelationId FBSCorrelationId::Create()
{
	FBSCorrelationId Result;
	Result.Value = CreateNonZeroGuid();
	return Result;
}

bool FBSCorrelationId::TryParse(const FString& Text, FBSCorrelationId& OutId)
{
	OutId.Reset();
	return TryParseCanonicalGuid(Text, OutId.Value);
}

bool FBSCorrelationId::IsValid() const
{
	return Value.IsValid();
}

FString FBSCorrelationId::ToString() const
{
	return IsValid() ? Value.ToString(EGuidFormats::DigitsWithHyphensLower) : FString();
}

const FGuid& FBSCorrelationId::GetGuid() const
{
	return Value;
}

void FBSCorrelationId::Reset()
{
	Value.Invalidate();
}

FBSCommandEnvelope FBSCommandEnvelope::CreateRoot()
{
	FBSCommandEnvelope Result;
	Result.CommandIdValue = FBSCommandId::Create();
	do
	{
		Result.CorrelationIdValue = FBSCorrelationId::Create();
	}
	while (Result.CorrelationIdValue.GetGuid() == Result.CommandIdValue.GetGuid());

	return Result;
}

bool FBSCommandEnvelope::TryCreate(
	const FBSCommandId& CommandId,
	const FBSCorrelationId& CorrelationId,
	FBSCommandEnvelope& OutEnvelope)
{
	OutEnvelope.Reset();

	if (!CommandId.IsValid() || !CorrelationId.IsValid())
	{
		return false;
	}

	OutEnvelope.CommandIdValue = CommandId;
	OutEnvelope.CorrelationIdValue = CorrelationId;
	return true;
}

bool FBSCommandEnvelope::TryCreateChild(
	const FBSCommandEnvelope& Parent,
	FBSCommandEnvelope& OutEnvelope)
{
	OutEnvelope.Reset();

	if (!Parent.IsValid())
	{
		return false;
	}

	FBSCommandId ChildCommandId;
	do
	{
		ChildCommandId = FBSCommandId::Create();
	}
	while (ChildCommandId == Parent.CommandIdValue
		|| ChildCommandId.GetGuid() == Parent.CorrelationIdValue.GetGuid());

	return TryCreate(ChildCommandId, Parent.CorrelationIdValue, OutEnvelope);
}

bool FBSCommandEnvelope::IsValid() const
{
	return CommandIdValue.IsValid() && CorrelationIdValue.IsValid();
}

const FBSCommandId& FBSCommandEnvelope::GetCommandId() const
{
	return CommandIdValue;
}

const FBSCorrelationId& FBSCommandEnvelope::GetCorrelationId() const
{
	return CorrelationIdValue;
}

void FBSCommandEnvelope::Reset()
{
	CommandIdValue.Reset();
	CorrelationIdValue.Reset();
}
