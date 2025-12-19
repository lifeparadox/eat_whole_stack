local eatWholeStack = {}
eatWholeStack.contextMenu = {}

---@class FoodList @property type
eatWholeStack.FoodList = {
  items = {},
  count = 0,
  icon = nil
}

---@param player_body BodyDamage
---@param food_item Food
---@return number
eatWholeStack.getFoodTimeHealthFromFoodTimer = function(player_body, food_item)
  local health_from_food_timer = player_body:getHealthFromFoodTimer()
  local get_health_from_food_time_by_hunger = 3000.0
  local food_item_hunger_change = food_item:getHungerChange()

  local food_time_health_from_food_timer = health_from_food_timer +
      food_item_hunger_change * get_health_from_food_time_by_hunger


  return food_time_health_from_food_timer
end


---@param items_list InventoryItem[] | umbrella.ContextMenuItemStack[]
---@return FoodList?
function eatWholeStack.getFoodList(items_list)
  local food_list = {
    items = {},
    count = 0,
    icon = nil
  }

  --Check if item list is ContextMenuItemStack[] or InventoryItem[]
  if not instanceof(items_list[1], "InventoryItem") then
    local skip_first_item = true
    for key, item_table in ipairs(items_list) do
      ---@cast item_table ContextMenuItemStack
      for key, item in ipairs(item_table.items) do
        ---@cast item InventoryItem
        if item and item:getStringItemType() == 'Food' and item:getScriptItem():isCantEat() == false then
          if skip_first_item then
            skip_first_item = false
          else
            local _item = item;
            food_list.items[food_list.count] = _item
            food_list.count = food_list.count + 1
            food_list.icon = _item:getIcon()
          end
        else
          return
        end
      end
    end
  else
    for key, item in ipairs(items_list) do
      ---@cast item InventoryItem
      if item and item:getStringItemType() == 'Food' and item:getScriptItem():isCantEat() == false then
        local _item = item;
        food_list.items[food_list.count] = _item
        food_list.count = food_list.count + 1
        food_list.icon = _item:getIcon()
      else
        return
      end
    end
  end
  return food_list
end

---@param player_index integer
---@param food_list FoodList
---@return InventoryItem[]
function eatWholeStack.howManyCanEat(player_index, food_list)
  local eatingThisItems = {}
  local player = getSpecificPlayer(player_index)
  local player_body = player:getBodyDamage()
  -- or eatan_food_timer
  local health_from_food_timer = player_body:getHealthFromFoodTimer()

  local standard_health_from_food_time = player_body:getStandardHealthFromFoodTime()
  local needed_food_timer = standard_health_from_food_time * 3.0

  local hunger_level = player:getStats():get(CharacterStat.HUNGER)



  for key, item in ipairs(food_list.items) do
    --NOTE: always item is food
    ---@diagnostic disable-next-line: need-check-nil
    ---@type number
    local itemHunger = item:getHungerChange()
    eatingThisItems[key] = item


    hunger_level = hunger_level - (itemHunger * -1)
    if hunger_level < 0 then
      break
    else
      -- local item_from_food_timer = eatWholeStack.getFoodTimeHealthFromFoodTimer(player_body, item)
      -- health_from_food_timer = health_from_food_timer + (item_from_food_timer * -1)
      -- print("------")
      -- print(item_from_food_timer)
    end
    -- if health_from_food_timer > needed_food_timer then

    --   break
    -- end
  end
  return eatingThisItems
end

---@param player_index integer
---@return InventoryItem?
function eatWholeStack.getWornMask(player_index)
  local player = getSpecificPlayer(player_index)
  local mask = player:getWornItem(ItemBodyLocation.MASK)
  return mask
end

---@param food_list FoodList
---@param player_index integer
function eatWholeStack.eatStack(food_list, player_index)
  local player = getSpecificPlayer(player_index)


  local eatingThisItems = eatWholeStack.howManyCanEat(player_index, food_list)


  for _, item in ipairs(eatingThisItems) do
    ISInventoryPaneContextMenu.transferIfNeeded(player, item)
  end

  local mask = eatWholeStack.getWornMask(player_index)
  if mask then
    ISTimedActionQueue.add(ISUnequipAction:new(player, mask, 50))
  end

  for _, item in ipairs(eatingThisItems) do
    ISTimedActionQueue.add(ISEatFoodAction:new(player, item, 1.0));
  end

  if mask then
    ISTimedActionQueue.add(ISWearClothing:new(player, mask))
  end
end

---@param player_index integer
---@param context ISContextMenu
---@param items_list InventoryItem[] | umbrella.ContextMenuItemStack[]
function eatWholeStack.contextMenu.onFillContextMenu(player_index, context, items_list)
  local player = getSpecificPlayer(player_index)
  -- local items_list = ISInventoryPane.getActualItems(items)
  local food_list = eatWholeStack.getFoodList(items_list)

  if not food_list then
    return
  end



  ---@diagnostic disable-next-line: unnecessary-if
  if food_list.count > 1 then
    local context_menu = context:addOption(getText('IGUI_eatWholeStack'), food_list, eatWholeStack.eatStack,
      player_index)
    context_menu.iconTexture = food_list.icon
    if player:getMoodles():getMoodleLevel(MoodleType.FOOD_EATEN) >= 3 then
      context_menu.notAvailable = true
      local tooltip = ISInventoryPaneContextMenu.addToolTip();
      tooltip.description = getText("Tooltip_CantEatMore");
      context_menu.toolTip = tooltip
    end
  end
end

---@diagnostic disable-next-line: param-type-mismatch
Events.OnFillInventoryObjectContextMenu.Add(eatWholeStack.contextMenu.onFillContextMenu)


logg = function(f)
  log(DebugType.Action, f)
end
