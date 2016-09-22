#include <bcm_host.h>
#include <stdio.h>
#include <unistd.h>
#include <malloc.h>

void res( const char* str, uint32_t val )
{
	if ( val != 0 )
	{
		printf( "%s: %08x\n", str, val );
	}
}

unsigned int roundUp( unsigned int x, unsigned int y )
{
	return y*((x + y-1)/y);
}

uint16_t* loadBitmap( char* filename, uint32_t width, uint32_t height, int* pitch )
{
	*pitch = roundUp( 2*width, 32 );
	uint16_t* bitmap = (uint16_t*)malloc(*pitch*height);
	FILE* f = fopen( filename, "rb" );
	int fail = 1;
	int x, y;
	if ( f != NULL )
	{
		fail = 0;
		for ( y = 0; y < height; y++ )
		{
			for ( x = 0; x < width; x++ )
			{
				uint8_t r, g, b;
				if ( fread( &r, 1, 1, f ) != 1 ) { fail = 1; break; }
				if ( fread( &g, 1, 1, f ) != 1 ) { fail = 1; break; }
				if ( fread( &b, 1, 1, f ) != 1 ) { fail = 1; break; }
				bitmap[y*(*pitch>>1) + x] = ((r&0x1f)<<11) | ((g&0x3f)<<5) | (b&0x1f);
			}
			if ( fail )
			{
				break;
			}
		}
	}
	if ( fail )
	{
		for ( x = 0; x < width; x++ )
		{
			for ( y = 0; y < height; y++ )
			{
				uint16_t r = x%width < width/2 ? 0x1f : 0x0f;
				uint16_t g = y%height < height/2 ? 0x3f : 0x1f;
				uint16_t b = (x+y)%(width+height) < (width+height)/2 ? 0x1f : 0x0f;
				bitmap[y*(*pitch>>1) + x] = ((r&0x1f)<<11) | ((g&0x3f)<<5) | (b&0x1f);
			}
		}
	}

	return bitmap;
}

void displayInfo( int id, char* name )
{
	uint32_t width, height;
	int res = graphics_get_display_size( id, &width, &height );
	if ( res >= 0 )
	{
		printf( "\t%d %s: %dx%d\n", id, name, width, height );
	}
}

void usage( char* name )
{
	printf( "usage: %s <display> <file>\n", name );
	displayInfo( DISPMANX_ID_MAIN_LCD, "Main LCD" );
	displayInfo( DISPMANX_ID_AUX_LCD, "AUX LCD" );
	displayInfo( DISPMANX_ID_HDMI, "HDMI" );
	displayInfo( DISPMANX_ID_SDTV, "SDTV" );
	displayInfo( DISPMANX_ID_FORCE_LCD, "Force LCD" );
	displayInfo( DISPMANX_ID_FORCE_TV, "Force TV" );
	displayInfo( DISPMANX_ID_FORCE_OTHER, "Force other" );
	exit( 1 );
}

int main( int argc, char** argv )
{
	bcm_host_init();
	if ( argc < 4 )
	{
		usage( argv[0] );
	}
	int screen = atoi( argv[1] );
	int time = atoi( argv[2] );
	int pitch;
	int i;
	uint32_t x, y;
	int width, height;
	res( "get display size", graphics_get_display_size( screen, &width, &height ) );
	printf( "display %d: %d x %d\n", screen, width, height );
	DISPMANX_DISPLAY_HANDLE_T display = vc_dispmanx_display_open( screen );
	uint16_t* bitmap = loadBitmap( argv[3], width, height, &pitch );

	// create a texture
	uint32_t imagePtr;
	DISPMANX_RESOURCE_HANDLE_T texture = vc_dispmanx_resource_create( VC_IMAGE_RGB565, width, height, &imagePtr );

	VC_RECT_T copyRect, blitRect, screenRect;
	res( "rect set", vc_dispmanx_rect_set( &copyRect, 0, 0, width, height ) );
	res( "rect set", vc_dispmanx_rect_set( &blitRect, 0, 0, width<<16, height<<16 ) );
	res( "rect set", vc_dispmanx_rect_set( &screenRect, 0, 0, width, height ) );

	DISPMANX_UPDATE_HANDLE_T update = vc_dispmanx_update_start( 10 );
	VC_DISPMANX_ALPHA_T alpha = { DISPMANX_FLAGS_ALPHA_FROM_SOURCE | DISPMANX_FLAGS_ALPHA_FIXED_ALL_PIXELS, 255, 0 };
	DISPMANX_ELEMENT_HANDLE_T element = vc_dispmanx_element_add( update, display, 2000, &screenRect, texture, &blitRect, DISPMANX_PROTECTION_NONE, &alpha, NULL, VC_IMAGE_ROT0 );
	res( "submit", vc_dispmanx_update_submit_sync( update ) );
	res( "resource write data", vc_dispmanx_resource_write_data( texture, VC_IMAGE_RGB565, pitch, bitmap, &copyRect ) );
	
	sleep( time );
	update = vc_dispmanx_update_start( 10 );

	res( "element remove", vc_dispmanx_element_remove( update, element ) );
	res( "submit", vc_dispmanx_update_submit_sync( update ) );
	res( "resource delete", vc_dispmanx_resource_delete( texture ) );
	res( "display close", vc_dispmanx_display_close( display ) );
	return 0;
}
