class FileBuffer
{
    string data = "";
    int readPos = 0;

    FileBuffer()
    {

    }

    string getData()
    {
        return data;
    }

    FileBuffer(File &f)
    {        
        while ( !f.EOFReached() )
        {
            data += f.ReadCharacter();
        }

        f.Close();
    }


    uint8 FromAscii( uint8 n )
    {
        if (n >= 65)
            return (n - 55);

        return ( n - 48);
    }


    uint8 ToAscii(uint8 n)
    {        
        if (n >= 10)
            return (n + 55);

        return (n + 48);
    }

    void writeByte(uint8 b)
    {        
        uint8 nib0 = ((b & 0xF0)>>4);
        uint8 nib1 = (b & 0x0F);

        data += ToAscii(nib0);
        data += ToAscii(nib1);
    }

    uint readByte( )
    {
        uint8 nib0 = FromAscii(data[readPos++]);
        uint8 nib1 = FromAscii(data[readPos++]);

        return ((nib1) + (nib0 << 4));
    }

    int ReadInt32()
    {
        int ret = 0;
        int shift = 0;

        for (int i = 0; i < 4; i++)
        {
            int read = readByte();

            read <<= shift;

            shift += 8;

            ret += read;            
        }

        return ret;
    }

    string ReadString(int len)
    {
        string ret = "";

        while (len-- > 0)
        {
            ret += readByte();
        }
        return ret;
    }

    float ReadFloat()
    {
        uint retInt = uint(ReadInt32());

        return fpFromIEEE(retInt);

    }

    void Write(int i)
    {        
        int shift = 0;

        for ( int x = 0; x < 4; x ++ )
        {
            writeByte(i&0xFF);
            shift += 8;
            i>>=shift;
        }
    }

    void Write(float f)
    {
        uint ret = fpToIEEE(f);

        Write(int(ret));        
    }

    void Write(string s, int len)
    {

        for ( int i = 0; i < len; i ++ )
        {
            if ( s[i] == 0 )
                break;
                
            writeByte(s[i]);
            len--;
        }

        while (len-- > 0)
        {
            writeByte(0);
        }
    }
}