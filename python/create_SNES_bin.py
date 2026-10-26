# Structure of a SNES tilemap word: [V-Flip(1)][H-Flip(1)][Priority(1)][Palette(3)][Tile Index(10)]
# Let's say palette 0 is bits 10-12 (value 0), so we just write the tile index as a little-endian 16-bit word.

def create_snes_tilemap():
    width = 32
    height = 32
    blank_tile = 0x0019
    
    # Initialize a 32x32 grid with blank tiles
    grid = [[blank_tile for _ in range(width)] for _ in range(height)]
    
    # Example: Place "- Nintendo -" at row 12, columns 12 to 19
    nintendo_tiles = [0x0002, 0x0003, 0x0004, 0x0005, 0x0006, 0x0007, 0x0008, 0x0009]
    for i, tile in enumerate(nintendo_tiles):
        grid[12][12 + i] = tile
    nintendo_tiles=[]
    nintendo_tiles = [ 0x0012, 0x0013, 0x0014, 0x0015, 0x0016, 0x0017, 0x0018]
    for i, tile in enumerate(nintendo_tiles):
            grid[13][12 + i] = tile

    # Write out to a raw binary file
    with open("intro_screen.bin", "wb") as f:
        for row in grid:
            for tile in row:
                # SNES expects 16-bit words in little-endian format (low byte, then high byte)
                f.write(tile.to_bytes(2, byteorder='little'))

if __name__ == "__main__":
    create_snes_tilemap()