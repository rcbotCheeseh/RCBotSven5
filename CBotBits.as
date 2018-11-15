
final class CBits
{
	CBits ( int length )
	{
		bits = array<int>((length/32) + 1);
	}

	bool getBit ( int longbit )
	{
		int bit = 1<<(longbit % 32);
		int byte = longbit / 32;

		//? ????
		if ( uint(byte) < bits.length() )	
			return (bits[byte] & bit) == bit;

		return false;
	}

	void setBit ( int longbit , bool val )
	{
		int bit = 1<<(longbit % 32);
		int byte = longbit / 32;

		if ( val )
			bits[byte] |= bit;
		else
			bits[byte] &= ~bit;
	}

	void reset ()
	{
		for ( uint i = 0; i < bits.length(); i ++  )
		{
			bits[i] = 0;
		}
	}

	array<int> bits;
}

