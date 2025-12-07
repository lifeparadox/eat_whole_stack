local eatWholeStack = {}
eatWholeStack.contextMenu = {}


---@param player_index integer
---@param items (InventoryItem | umbrella.ISInventoryPane.ItemRecord)[]
---@return InventoryItem[]
function eatWholeStack.howManyCanEat(player_index, items)
  local eatingThisItems = {}
  local player = getSpecificPlayer(player_index)
  local hungerLevel = player:getStats():getHunger()

  for key, item in ipairs(items) do
    --NOTE: always item is food
    ---@diagnostic disable-next-line: need-check-nil
    ---@type number
    local itemHunger = item:getHungerChange()
    eatingThisItems[key] = item
    hungerLevel = hungerLevel - (itemHunger * -1)
    if hungerLevel < 0 then
      break
    end
  end
  return eatingThisItems
end

---@param player_index integer
---@return InventoryItem?
function eatWholeStack.getWornMask(player_index)
  local player = getSpecificPlayer(player_index)
  local mask = player:getWornItem("Mask")
  return mask
end

---@param items (InventoryItem | umbrella.ISInventoryPane.ItemRecord)[]
---@param player_index integer
function eatWholeStack.eatStack(items, player_index)
  local player = getSpecificPlayer(player_index)
  local eatingThisItems = eatWholeStack.howManyCanEat(player_index, items)
  local foodeaten = player

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
---@param items (InventoryItem | umbrella.ISInventoryPane.ItemRecord)[]
function eatWholeStack.contextMenu.onFillContextMenu(player_index, context, items)
  local player = getSpecificPlayer(player_index)
  local items_list = ISInventoryPane.getActualItems(items)
  local count = 0
  local icon = nil

  for _, item in ipairs(items_list) do
    if item and item:getStringItemType() == 'Food' and item:getScriptItem():isCantEat() == false then
      count = count + 1
      icon = item:getIcon()
    else
      return
    end
  end

  if count > 1 then
    local context_menu = context:addOption(getText('IGUI_eatWholeStack'), items_list, eatWholeStack.eatStack,
      player_index)
    context_menu.iconTexture = icon
    if player:getMoodles():getMoodleLevel(MoodleType.FoodEaten) >= 3 then
      context_menu.notAvailable = true
      local tooltip = ISInventoryPaneContextMenu.addToolTip();
      tooltip.description = getText("Tooltip_CantEatMore");
      context_menu.toolTip = tooltip
    end
  end
end

---@diagnostic disable-next-line: param-type-mismatch
Events.OnFillInventoryObjectContextMenu.Add(eatWholeStack.contextMenu.onFillContextMenu)
