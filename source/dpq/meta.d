module dpq.meta;

import dpq.attributes;

import std.traits;
import std.datetime : SysTime;

version(unittest) import std.stdio;

deprecated("Use SQLType instead, not all array types are supported by sqlType")
string sqlType(T)()
{
	// TODO: More types, embedded structs, Date types

	static if (isArray!T)
		alias FT = ForeachType!T;
	else
		alias FT = T;

	static if (is(FT == int) || is(FT == ushort))
		enum type = "INT";
	else static if (is(FT == long) || is(FT == uint))
		enum type = "INT8";
	else static if (is(FT == short))
		enum type = "INT2";
	else static if (is(FT == long))
		enum type = "BIGINT";
	else static if (is(FT == float))
		enum type = "FLOAT4";
	else static if (is(FT == double))
		enum type = "FLOAT8";
	else static if (is(FT == char[]) || is(FT == string))
		enum type = "TEXT";
	else static if (is(FT == bool))
		enum type = "BOOL";
	else static if (is(FT == char))
		enum type = "CHAR(1)";
	else static if(is(FT == ubyte[]) || is(FT == byte[]))
		enum type = "BYTEA";
	else static if (is(FT == enum))
		enum type = sqlType!(OriginalType!FT);
	else
		static assert(false, "Cannot map type \"" ~ T.stringof ~ "\" to any PG type, please specify it manually using @type.");

	static if (isArray!T)
	{
		static if (isStaticArray!T)
			return type ~ "[%d]".format(T.length);
		else
			return type ~ "[]";
	}
	else
		return type;
}

/**
	Returns the array's base type

	Returns the string type for any type that returns true
	for isSomeString!T

	Examples:
	---------------
	alias T = BaseType!(int[][]);
	alias T2 = BaseType!(int[]);
	alias T3 = BaseType!int;
	alias T4 = BaseType!(string[])

	static assert(is(T == int));
	static assert(is(T2 == int));
	static assert(is(T3 == int));
	static assert(is(T4 == string));
	---------------
*/
template BaseType(T)
{
	static if (isArray!T && !isSomeString!T)
		alias BaseType = BaseType!(ForeachType!T);
	else
		alias BaseType = Unqual!T;
}

unittest
{
	writeln(" * meta");
	writeln("\t * BaseType");

	static assert(is(BaseType!(int[][][]) == int));
	static assert(is(BaseType!(string[]) == string));
	static assert(is(BaseType!string == string));
	static assert(is(BaseType!dstring == dstring));
}

template SQLType(T)
{
	alias BT = BaseType!T;

	static if(is(T == ubyte[]) || is(T == byte[]))
		enum SQLType = "BYTEA";
	else
	{
		static if (isSomeString!BT)
			enum type = "TEXT";
		else static if (is(BT == SysTime))
			enum type = "timestamp";
		else static if (is(BT == int))
			enum type = "INT4";
		else static if (is(BT == long))
			enum type = "INT8";
		else static if (is(BT == short))
			enum type = "INT2";
		else static if (is(BT == float))
			enum type = "FLOAT4";
		else static if (is(BT == double))
			enum type = "FLOAT8";
		else static if (is(BT == bool))
			enum type = "BOOL";
		else static if (is(BT == char))
			enum type = "CHAR(1)";
		else static if (is(BT == enum))
			enum type = SQLType!(OriginalType!BT);
		else
			static assert(false,
					"Cannot map type \"" ~ T.stringof ~ "\" to any PG type, " ~
					"please note that embedded structures need an @embed " ~
					"or @type attribute if you do not wish to embed them.");

		static if (isArray!T && !isSomeString!T)
			enum SQLType = type ~ "[]";
		else 
			enum SQLType = type;
	}
}

unittest
{
	writeln("\t * SQLType");

	static assert(SQLType!int == "INT4");
	static assert(SQLType!long == "INT8");
	static assert(SQLType!float == "FLOAT4");
	static assert(SQLType!(int[]) == "INT4[]");
	static assert(SQLType!(long[]) == "INT8[]");
	static assert(SQLType!(double[]) == "FLOAT8[]");
	static assert(SQLType!(string) == "TEXT");
	static assert(SQLType!(string[]) == "TEXT[]");
	static assert(SQLType!(ubyte[]) == "BYTEA");
}

/**
	Returns the number of dimensions of the given array type

	Examples:
	-----------------
	auto dims = ArrayDimensions!(int[][]);
	static assert(dims == 2);
	-----------------
 */
template ArrayDimensions(T)
{
	static if (isArray!T)
		enum ArrayDimensions = 1 + ArrayDimensions!(ForeachType!T);
	else 
		enum ArrayDimensions = 0;
}

unittest
{
	writeln("\t * ArrayDimensions");

	static assert(ArrayDimensions!int == 0);
	static assert(ArrayDimensions!(int[]) == 1);
	static assert(ArrayDimensions!(int[][]) == 2);
	static assert(ArrayDimensions!(int[][][]) == 3);
}


template ShouldRecurse(alias TA)
{
	alias T = typeof(TA);
	static if (is(T == class) || is(T == struct))
		static if (hasUDA!(TA, EmbedAttribute))
			enum ShouldRecurse = true;
		else
			enum ShouldRecurse = false;
	else
		enum ShouldRecurse = false;
}
