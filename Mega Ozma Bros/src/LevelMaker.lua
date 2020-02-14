LevelMaker = Class{}

function LevelMaker.generate(width, height)
    local tiles = {}
    local entities = {}
    local objects = {}

    local tileID = TILE_ID_GROUND
    
-- Whether to draw the tiles with toppers
    local topper = true
    local tileset = math.random(20)
    local topperset = math.random(20)

-- LockBlock and key
    lockVariant = math.random(#LOCK_VARIANTS)

    local lockBlockPosition = math.random(width)
    lockBlockPosition = 5

    local keyPosition = math.random(width)
    keyPosition = 8

    keyTaken = false

-- Loop until they spawn in different positions
    while keyPosition == lockBlockPosition do
        keyPosition = math.random(width)
    end

-- Insert blank tables into tiles for later access
    for x = 1, height do
        table.insert(tiles, {})
    end

-- Column by column generation instead of row; sometimes better for platformers
    for x = 1, width do
        local tileID = TILE_ID_EMPTY
        
-- Lay out the empty space
        for y = 1, 6 do
            table.insert(tiles[y],
                Tile(x, y, tileID, nil, tileset, topperset))
        end

-- Chance to just be emptiness
        if x ~=1 and x~= lockBlockPosition and x ~= keyPosition and x < width - 3 and math.random(7) == 1 then
            for y = 7, height do
                table.insert(tiles[y],
                    Tile(x, y, tileID, nil, tileset, topperset))
            end
        else
            tileID = TILE_ID_GROUND

            local blockHeight = 4

            for y = 7, height do
                table.insert(tiles[y],
                    Tile(x, y, tileID, y == 7 and topper or nil, tileset, topperset))
            end
               
-- Don't spawn anything else then the ground in the last 3 columns 
 -- This will be the position where the flag will appear
            if x >= width - 3 then
                goto continue
            end

-- Chance to generate a pillar
            if math.random(8) == 1 then
                blockHeight = 2
                
-- Chance to generate bush on pillar
                if math.random(8) == 1 then
                    table.insert(objects, bushOnPillarMaker(x, y))
                end
                
                -- pillar tiles
                tiles[5][x] = Tile(x, 5, tileID, topper, tileset, topperset)
                tiles[6][x] = Tile(x, 6, tileID, nil, tileset, topperset)
                tiles[7][x].topper = nil
            
-- Chance to generate bushes
            elseif math.random(8) == 1 then
                table.insert(objects, bushMaker(x, y))
            end

-- Chance to spawn a block
            if x == lockBlockPosition then
                table.insert(objects, lockMaker(x, y, blockHeight, objects))
            elseif x == keyPosition then
                table.insert(objects, keyMaker(x, y, blockHeight, objects))
            elseif math.random(10) == 1 then
                table.insert(objects, blockMaker(x, y, blockHeight, objects))
            end
        end

        ::continue::
    end

    local map = TileMap(width, height)
    map.tiles = tiles
    
    gameLevel = GameLevel(entities, objects, map)
    return gameLevel
end

function lockMaker(x, y, blockHeight, objects)
    return GameObject {
        texture = 'keys-and-locks',
        x = (x - 1) * TILE_SIZE,
        y = (blockHeight - 1) * TILE_SIZE,
        width = 16,
        height = 16,

        -- make it a random variant
        frame = 4 + lockVariant,
        collidable = true,
        hit = false,
        solid = true,

        -- collision function takes itself
        onCollide = function(obj)           
            gSounds['powerup-reveal']:play()
            for k, object in pairs(objects) do
                if keyTaken and object == obj then
                    table.remove(objects, k)
                    gameLevel:spawnLevelEnd()
                end
            end
        end,

        onConsume = function(obj)
        end

    }
end

function keyMaker(x, y, blockHeight, objects)
-- Key
    return GameObject {
        texture = 'keys-and-locks',
        x = (x - 1) * TILE_SIZE,
        y = (blockHeight - 1) * TILE_SIZE,
        width = 16,
        height = 16,

-- Make it a random variant
        frame = lockVariant,
        collidable = true,
        consumable = true,
        hit = false,
        solid = false,

-- Collision function takes itself
        onConsume = function(obj)

-- Remove this check
            if not obj.hit then
--Use another sound
                gSounds['powerup-reveal']:play()

                obj.hit = true
                keyTaken = true
            end

        end
    }
end

function blockMaker(x, y, blockHeight, objects) 
-- Jump block
    return GameObject {
        texture = 'jump-blocks',
        x = (x - 1) * TILE_SIZE,
        y = (blockHeight - 1) * TILE_SIZE,
        width = 16,
        height = 16,
        
-- Make it a random variant
        frame = math.random(#JUMP_BLOCKS),
        collidable = true,
        hit = false,
        solid = true,

-- Collision function takes itself
        onCollide = function(obj)

-- Spawn a gem if you haven't already hit the block
            if not obj.hit then

-- Chance to spawn gem, not guaranteed
                if math.random(5) == 1 then

-- maintain reference to set it to nil
                    local gem = GameObject {
                        texture = 'gems',
                        x = (x - 1) * TILE_SIZE,
                        y = (blockHeight - 1) * TILE_SIZE - 4,
                        width = 16,
                        height = 16,
                        frame = math.random(#GEMS),
                        collidable = true,
                        consumable = true,
                        solid = false,

-- Gem has its own function to add to the player's score
                        onConsume = function(player, object)
                            gSounds['pickup']:play()
                            player.score = player.score + 100
                        end
                    }
                    
-- Make the gem move up from the block and play a sound
                    Timer.tween(0.1, {
                        [gem] = {y = (blockHeight - 2) * TILE_SIZE}
                    })
                    gSounds['powerup-reveal']:play()

                    table.insert(objects, gem)
                end

                obj.hit = true
            end

            gSounds['empty-block']:play()
        end
    }
end

function bushOnPillarMaker(x, y) 
    return GameObject {
        texture = 'bushes',
        x = (x - 1) * TILE_SIZE,
        y = (4 - 1) * TILE_SIZE,
        width = 16,
        height = 16,
        
-- Select random frame from bush_ids whitelist, then random row for variance
        frame = BUSH_IDS[math.random(#BUSH_IDS)] + (math.random(4) - 1) * 7
    }
end

function bushMaker(x, y)
    return GameObject {
        texture = 'bushes',
        x = (x - 1) * TILE_SIZE,
        y = (6 - 1) * TILE_SIZE,
        width = 16,
        height = 16,
        frame = BUSH_IDS[math.random(#BUSH_IDS)] + (math.random(4) - 1) * 7,
        collidable = false
    }
end