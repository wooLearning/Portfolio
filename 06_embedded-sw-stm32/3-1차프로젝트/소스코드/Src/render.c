#include <string.h>
#include <stdbool.h>
#include "main.h"
#include "sprite_data.h"
#include "test_tilemap.h"
#include "village_tileset.h"

#define	SCREEN_WIDTH	320
#define	SCREEN_HEIGHT	240

#ifndef MIN
#define MIN(a,b)  (((a) < (b)) ? (a) : (b))
#endif

/**************************************************************************************************
 *                                      Sprite Code                                               *
 * Code to draw sprites into a scanline buffer. `screen_sprites` contains all visible sprites.    *
 * The 'active sprites' for a scanline are determined and the appropriate pixels from the sprite  *
 * for scanline copied into the scanline buffer where pixels of the `transparent_colour` are      *
 * skipped allowing transparency in the sprites.                                                  *
 **************************************************************************************************/

typedef struct {
    const uint16_t* data_ptr;
    unsigned int height;
    int x;
    int y;
    bool enabled;
} sprite_info_t;

#define NUM_SPRITES 128
#define MAX_SPRITES_PER_LINE 20
#define SPRITE_WIDTH 16

sprite_info_t screen_sprites[NUM_SPRITES];
int sprite_scroll_x = 0;
int sprite_scroll_y = 0;

const uint16_t transparent_colour = 0x7c1f;

static void init_sprites() {
    for(int i = 0;i < NUM_SPRITES; ++i) {
        screen_sprites[i].enabled = false;
    }
}

typedef struct {
    // Single line of sprite data for scanline sprite is active for
    const uint16_t* line_data;
    // Screen X coordinate sprite starts at
    uint16_t x;
} active_sprite_t;

active_sprite_t cur_active_sprites[MAX_SPRITES_PER_LINE];

// Return true is scanline with Y coordiate `line_y` contains `sprite`
static bool is_sprite_on_line(sprite_info_t sprite, uint16_t line_y) {
    return (sprite.y <= line_y) && (line_y < sprite.y + sprite.height);
}

static active_sprite_t calc_active_sprite_info(sprite_info_t sprite, uint16_t line_y) {
    int sprite_line = line_y - sprite.y;

    return (active_sprite_t){
        .line_data = sprite.data_ptr + sprite_line * SPRITE_WIDTH,
        .x = sprite.x
    };
}

static int determine_active_sprites(uint16_t line_y) {
    int num_active_sprites = 0;

    // Iterate through all sprites
    for(int i = 0;i < NUM_SPRITES; ++i) {
        if (screen_sprites[i].enabled && is_sprite_on_line(screen_sprites[i], line_y)) {
            // If sprite is enabled and is on the given scanline add it to the active sprites
            cur_active_sprites[num_active_sprites++] =
                calc_active_sprite_info(screen_sprites[i], line_y);

            if (num_active_sprites == MAX_SPRITES_PER_LINE) {
                break;
            }
        }
    }

    return num_active_sprites;
}

static inline uint16_t ENCODE_RGB(uint8_t R, uint8_t G, uint8_t B) { // R[5]:G[6]:B[5] in little endian
  uint8_t firstByte, secondByte;
  firstByte = ((R&0x1f)<<3) | ((G&0x38)>>3);
  secondByte  = ((G&0x07)<<5) | ((B&0x1f));
  return (secondByte<<8) | firstByte;
}

static void draw_sprite_to_line(uint16_t* line_buffer, active_sprite_t sprite) {
    // Determine where on the scanline the sprite starts (start_line_x) and which pixel from the
    // active sprite line will be drawn first (sprite_draw_x).
    int sprite_draw_x;
    int start_line_x;

    // Sprite position given in absolute coordinates. Determine where it is on the screen given
    // the current scroll
    int screen_x = sprite.x - sprite_scroll_x;

    if (screen_x < 0) {
        // Sprite starts off screen so the sprite starts at the beginning of the scanline and the
        // first visible sprite pixel is determined from how far off screen the sprite is.
        sprite_draw_x = -screen_x;
        start_line_x = 0;
    } else {
        // Sprite starts on screen, so the first pixel from the sprite line will be drawn and the
        // sprite starts on scanline at it's X coordinate.
        sprite_draw_x = 0;
        start_line_x = screen_x;
    }

    // Determine where on the scanline the sprite ends.
    int end_line_x = MIN(screen_x + SPRITE_WIDTH, SCREEN_WIDTH);

    // Copy sprite pixels to scanline skipping transparent pixels
    for(int line_x = start_line_x; line_x < end_line_x; ++line_x, ++sprite_draw_x) {
        if (sprite.line_data[sprite_draw_x] != transparent_colour) {
#if 0
            line_buffer[line_x] = sprite.line_data[sprite_draw_x];
#else
            // For ILI9341, swap high and low bytes
            uint16_t pix = sprite.line_data[sprite_draw_x];
            uint8_t r = pix&0x1f, g = ((pix>>5)&0x1f)<<1, b = (pix>>10)&0x1f;
            line_buffer[line_x] = ENCODE_RGB(r,g,b);
#endif
        }
    }
}

// Draw all sprites (up to MAX_SPRITES_PRE_LINE) that are on a scanline in its line buffer
void draw_sprites_line(uint16_t line_y, uint16_t* line_buffer) {
    // Translate line_y screen coordinate into absolute sprite coordinate using the scroll
    line_y += sprite_scroll_y;

    int num_active_sprites = determine_active_sprites(line_y);

    for(int i = num_active_sprites - 1;i >= 0; --i) {
        draw_sprite_to_line(line_buffer, cur_active_sprites[i]);
    };
}

/**************************************************************************************************
 *                                 Tilemap Code                                                   *
 * Code to draw a tilemap into a scanline buffer. All information about a tilemap is held in a    *
 * structure `tilemap_info_t`. Tiles are a fixed 16x16 size.                                      *
 **************************************************************************************************/

typedef struct {
    // Width and height in tiles
    int width;
    int height;

    // Pointer to tile data. Each uint16_t specifies which tile from the tileset should be
    // displayed. Storage is row major order, so consecutive elements of a row of tiles are next to
    // one another.
    const uint8_t* tiles;
    // Tileset data in RGB555 format
    const uint16_t* tileset;

    // X and Y scroll in pixels for the tilemap
    int y_scroll;
    int x_scroll;
} tilemap_info_t;

#define TILE_WIDTH 16
#define TILE_HEIGHT 16
#define TILES_PER_LINE (SCREEN_WIDTH / TILE_WIDTH)

// Return a pointer to a row of tiles from a tilemap. Line is specified in terms of tiles.
static inline const uint8_t* get_tilemap_line(int line, tilemap_info_t tilemap) {
    return tilemap.tiles + line * tilemap.width;
}

// Return a pointer to a row of pixels from a tile in a tileset
static inline const uint16_t* get_tile_line(uint16_t tile_num, int tile_y, const uint16_t* tileset) {
    return tileset + tile_num * TILE_WIDTH * TILE_HEIGHT + tile_y * TILE_WIDTH;
}

// Given a scanline Y, draw the relevant pixels from the tilemap into the scanline buffer
void draw_tilemap_line(uint16_t line_y, tilemap_info_t tilemap, uint16_t* line_buffer) {
    // Translate from screen pixel coordinates to tile pixel coordinates using the scroll
    int layer_y = line_y + tilemap.y_scroll;
    int layer_x = tilemap.x_scroll;

    // Determine the tilemap Y of the line
    int tilemap_y = layer_y / TILE_HEIGHT;
    // Determine the pixel Y of the line within a tile
    int tile_y = layer_y % TILE_HEIGHT;

    // Determine the tilemap X of the leftmost pixel
    int tilemap_x = layer_x / TILE_WIDTH;
    // Determine the pixel X of the leftmost pixel within the first tile
    int first_tile_x = layer_x % TILE_HEIGHT;

    // Due to scroll the first and last tiles in the screen may only be partially displayed.
    // Determine with width of the first and last tiles
    int first_tile_visible_width = TILE_WIDTH - first_tile_x;
    int last_tile_visible_width = first_tile_x;

    // Obtain a pointer to the tilemap data for this line
    const uint8_t* tilemap_line = get_tilemap_line(tilemap_y, tilemap) + tilemap_x;
    // Draw the first tile to the line, this is a special case as it may not be full width
    // Get a pointer to the pixels for the line in the first tile, offset by first_tile_x
    const uint16_t* first_tile_line = get_tile_line(*tilemap_line, tile_y, tilemap.tileset) + first_tile_x;
    // Draw it to the buffer by copying the pixels
#if 0
    memcpy(line_buffer, first_tile_line, first_tile_visible_width * 2);
#else
    for (unsigned i=0; i<first_tile_visible_width; i++) {
        uint16_t pix = first_tile_line[i];
        uint8_t r = pix&0x1f, g = ((pix>>5)&0x1f)<<1, b = (pix>>10)&0x1f;
        line_buffer[i] = ENCODE_RGB(r,g,b);
    }
#endif

    ++tilemap_line;
    line_buffer += first_tile_visible_width;

    // Draw the remaining tiles in the line
    for(int tile = 1;tile < TILES_PER_LINE; ++tile) {
        // Get a pointer to the pixels for the line in the tile
        const uint16_t* tile_line = get_tile_line(*tilemap_line, tile_y, tilemap.tileset);
        // Draw it to the buffer by copying the pixels
#if 0
        memcpy(line_buffer, tile_line, TILE_WIDTH * 2);
#else
        for (unsigned i=0; i<TILE_WIDTH; i++) {
            uint16_t pix = tile_line[i];
            uint8_t r = pix&0x1f, g = ((pix>>5)&0x1f)<<1, b = (pix>>10)&0x1f;
            line_buffer[i] = ENCODE_RGB(r,g,b);
        }
#endif
        line_buffer += TILE_WIDTH;
        ++tilemap_line;
    }

    // When the first tile is only a partial tile, so is the final tile. Draw that final partial
    // tile here if required.
    if(first_tile_x != 0) {
        const uint16_t* last_tile_line = get_tile_line(*tilemap_line, tile_y, tilemap.tileset);
#if 0
        memcpy(line_buffer, last_tile_line, last_tile_visible_width * 2);
#else
        for (unsigned i=0; i<last_tile_visible_width; i++) {
            uint16_t pix = last_tile_line[i];
            uint8_t r = pix&0x1f, g = ((pix>>5)&0x1f)<<1, b = (pix>>10)&0x1f;
            line_buffer[i] = ENCODE_RGB(r,g,b);
        }
#endif
    }
}

/**************************************************************************************************
 *                                 Application Code                                               *
 * Using the video and sprite code from above draw a test pattern on screen along with a bunch of *
 * animated sprites                                                                               *
 **************************************************************************************************/

static const uint16_t* calc_sprite_ptr(int sprite_idx) {
    int num_sprite_pixels = SPRITE_WIDTH * sprite_height;

    return sprite_data + sprite_idx * num_sprite_pixels;
}

// Our test sprites have 4 different animations, each are walk cycles going in different directions
typedef enum {
    kWalkAnimUp = 0,
    kWalkAnimRight = 1,
    kWalkAnimDown = 2,
    kWalkAnimLeft = 3
} walk_anim_e;

#define FRAMES_PER_WALK_ANIM 3
#define ANIMS_FRAMES_PER_CHARACTER (FRAMES_PER_WALK_ANIM * 4)

// There's different characters in our sprite sheet. Given a character index, the animation and the
// frame of that animation return a pointer to the appropriate sprite.
static const uint16_t* calc_char_sprite_ptr(int character_idx, walk_anim_e anim, int anim_frame) {
    return calc_sprite_ptr(
        character_idx * ANIMS_FRAMES_PER_CHARACTER + anim * FRAMES_PER_WALK_ANIM + anim_frame);
}

// A very basic 'entity' system. This will allow us to place some moving animated sprites that walk
// around our tile map

// Each entity is either stationary or moving in a horizontal or verical direction
typedef enum {
    kMoveTypeNone,
    kMoveTypeHorizontal,
    kMoveTypeVertical,
} move_type_e;

// Entity data. Each entity has an associated sprite that it controls. The entity processing code
// move the sprite around (horizontally or vertically) playing the appropriate walk animation
typedef struct {
    // Index of the sprite associated with the entity
    int sprite_idx;

    // Index of the character the entity is using
    int character_idx;
    // Which frame within the current animation is being displayed (which animation can be
    // determined from the move_type and whether we're increasing or decreasing position)
    int anim_frame;

    // The entity either doesn't move at all or moves strictly horizontally or vertically. This
    // specifies the bounds for the movement (X coordinate bound for horizontal movement, Y
    // coordinate bound for vertical movement) and whether we're increasing or decreasing the
    // relevant coordinate for the movement.
    move_type_e move_type;
    int move_lower_bound;
    int move_upper_bound;
    bool move_increase;

    // When true entity should be processed
    bool enabled;
} entity_t;

#define NUM_ENTITIES 8

entity_t entities[NUM_ENTITIES];

// Given a tile X and Y, a movement type, an upper bound for the movement in tiles (lower bound
// taken from the start coordinates) and a character, setup an entity and sprite using the supplied
// indexes
void setup_entity(int start_tile_x, int start_tile_y, move_type_e move_type, int move_upper_bound,
    int character_idx, int entity_idx, int sprite_idx) {

    // Determine which animation to start with depending upon the movement type
    walk_anim_e initial_anim=kWalkAnimUp;
    switch(move_type) {
        case kMoveTypeNone: initial_anim = kWalkAnimDown; break;
        case kMoveTypeHorizontal: initial_anim = kWalkAnimRight; break;
        case kMoveTypeVertical: initial_anim = kWalkAnimDown; break;
    }

    int start_x = start_tile_x * TILE_WIDTH;
    int start_y = start_tile_y * TILE_HEIGHT;

    entities[entity_idx].sprite_idx = sprite_idx;
    entities[entity_idx].character_idx = character_idx;
    entities[entity_idx].anim_frame = 0;
    entities[entity_idx].move_type = move_type;
    // Our lower move bound is the start X for horizontal movement, and a Y coordinate otherwise
    entities[entity_idx].move_lower_bound = move_type == kMoveTypeHorizontal ? start_x : start_y;
    // Our upper move bound is given in terms of tiles, cover that to a pixel coordinate
    entities[entity_idx].move_upper_bound =
        move_upper_bound * (move_type == kMoveTypeHorizontal ? TILE_WIDTH : TILE_HEIGHT);
    entities[entity_idx].move_increase = true;
    entities[entity_idx].enabled = true;

    // Setup the sprite being used by the entity
    screen_sprites[sprite_idx].x = start_x;
    screen_sprites[sprite_idx].y = start_y;
    screen_sprites[sprite_idx].height = sprite_height;
    screen_sprites[sprite_idx].data_ptr = calc_char_sprite_ptr(character_idx, initial_anim, 0);
    screen_sprites[sprite_idx].enabled = true;

}

void setup_entities() {
    // Setup a few entities to walk around the map
    init_sprites();

    int cur_sprite_idx = 0;
    int cur_entity_idx = 0;

    setup_entity(2, 2, kMoveTypeVertical, 8, 0, cur_entity_idx++, cur_sprite_idx++);
    setup_entity(4, 7, kMoveTypeHorizontal, 14, 1, cur_entity_idx++, cur_sprite_idx++);
    setup_entity(7, 8, kMoveTypeHorizontal, 15, 2, cur_entity_idx++, cur_sprite_idx++);
    setup_entity(4, 15, kMoveTypeHorizontal, 10, 3, cur_entity_idx++, cur_sprite_idx++);
    setup_entity(18, 4, kMoveTypeVertical, 7, 4, cur_entity_idx++, cur_sprite_idx++);
    setup_entity(2, 12, kMoveTypeVertical, 22, 5, cur_entity_idx++, cur_sprite_idx++);
    setup_entity(7, 24, kMoveTypeHorizontal, 14, 0, cur_entity_idx++, cur_sprite_idx++);
}

int entity_frame = 0;

void process_entity(entity_t* entity) {
    // Keep a count of times process_entity is called. To have things move at a reasonable speed
    // we want to move the sprites less than once per frame (60 Hz framerate so that would be a
    // speed of 60 pixels/s). Animation also needs to run at a different speed otherwise the walk
    // cycle looks too quick.
    ++entity_frame;

    if ((entity_frame % 2) != 0) { // 4->2
        // Only do an update every 4 frames
        return;
    }

    // Set to true when we switch walking animations (when the entity reaches its upper or lower
    // bounds).
    bool new_anim = false;

    sprite_info_t* sprite = &screen_sprites[entity->sprite_idx];

    // Given the setting of move_increase and move_type alter X or Y appropriately. Check to see if
    // entity is hitting its upper or lower bound and if so start moving it in the oppposite
    // direction.
    if (entity->move_increase) {
        if (entity->move_type == kMoveTypeHorizontal) {
            sprite->x++;
            if (sprite->x == entity->move_upper_bound) {
                entity->move_increase = false;
                new_anim = true;
            }
        } else {
            sprite->y++;
            if (sprite->y == entity->move_upper_bound) {
                entity->move_increase = false;
                new_anim = true;
            }
        }
    } else {
        if (entity->move_type == kMoveTypeHorizontal) {
            sprite->x--;
            if (sprite->x == entity->move_lower_bound) {
                entity->move_increase = true;
                new_anim = true;
            }
        } else {
            sprite->y--;
            if (sprite->y == entity->move_lower_bound) {
                entity->move_increase = true;
                new_anim = true;
            }
        }
    }

    // Given the move_type and whether we are incrementing or decrementing position determine
    // which walking animation must be used.
    walk_anim_e anim;
    if (entity->move_type == kMoveTypeHorizontal) {
        anim = entity->move_increase ? kWalkAnimRight : kWalkAnimLeft;
    } else {
        anim = entity->move_increase ? kWalkAnimDown : kWalkAnimUp;
    }

    // Calculate the next animation frame for the entity, begin by keeping it the same
    int next_frame = entity->anim_frame;
    if (new_anim) {
        // For a new animation start at the first frame
        next_frame = 0;
    } else {
        if ((entity_frame % 4) == 0) { // 8->4
            // Go to the next frame of animation. Only do this every 8 entity frames so the
            // animation doesn't run too quickly.
            next_frame = entity->anim_frame + 1;
            if ((next_frame % FRAMES_PER_WALK_ANIM) == 0) {
                next_frame = 0;
            }
        }
    }
    entity->anim_frame = next_frame;

    // Determine the new sprite data pointer given the entities character index, the animation we
    // want and the frame
    sprite->data_ptr = calc_char_sprite_ptr(entity->character_idx, anim, next_frame);
}

// Go through all enabled entities that are move and process them
void process_entities() {
    for(int i = 0;i < NUM_ENTITIES; ++i) {
        if (entities[i].enabled && entities[i].move_type != kMoveTypeNone) {
            process_entity(&entities[i]);
        }
    }
}

tilemap_info_t test_tilemap;

// Setup our test tilemap to display the tilemap data in 'test_tilemap.h'
void setup_tilemap() {
    test_tilemap.width = tilemap_width;
    test_tilemap.height = tilemap_height;
    test_tilemap.tiles = tilemap_tiles;
    test_tilemap.tileset = tileset;
    test_tilemap.y_scroll = 0;
    test_tilemap.x_scroll = 0;
}

void draw_line(int line_y, uint8_t* line_buffer) {
    // For each line first draw the tilemap then the sprites over the top
    draw_tilemap_line(line_y, test_tilemap, (uint16_t *)line_buffer);
    draw_sprites_line(line_y, (uint16_t *)line_buffer);
}

bool y_inc = true;
bool x_inc = true;

void end_of_frame() {
    // Process all the entities
    process_entities();

    // Scroll the tilemap and sprites around together. Moving in both X and Y directions and
    // bouncing back when we reach the limits of the map. The extra - 1 adds a bit of variety to
    // the bouncing (without it they both share a large common divisor and it ends up bouncing in
    // same places over and over).
    if (test_tilemap.y_scroll >= ((tilemap_height * TILE_HEIGHT) - SCREEN_HEIGHT) - 1) {
        y_inc = false;
    } else if(test_tilemap.y_scroll <= 0) {
        y_inc = true;
    }

    if (test_tilemap.x_scroll >= ((tilemap_width * TILE_WIDTH) - SCREEN_WIDTH) - 1) {
        x_inc = false;
    } else if (test_tilemap.x_scroll <= 0) {
        x_inc = true;
    }

    if (y_inc) {
        test_tilemap.y_scroll++;
        sprite_scroll_y++;
    } else {
        test_tilemap.y_scroll--;
        sprite_scroll_y--;
    }

    if (x_inc) {
        test_tilemap.x_scroll++;
        sprite_scroll_x++;
    } else {
        test_tilemap.x_scroll--;
        sprite_scroll_x--;
    }
}

