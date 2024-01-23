# Microcraft Helper

## Description

This program aids in crafting items in modpacks that have a large number of
items and a large amount of crafting required (colloquially known as
"microcrafting").

You can feed it items and their crafting recipes (even if they are recursive),
then ask it to craft a specific item. It will give you a crafting plan including
all the items you need to craft and how many of each you need (and, if using 
machines, which machines to use).

## Usage

There are many menus in this program. You can navigate them with the arrow keys
and by pressing 'enter'.

### Main Menu

The main menu has the following options:

* [`Items`](#items) - View the list of items you have added to the program.
* [`Machines`](#machines) - View the list of machines you have added to the program.
* [`Crafting`](#crafting) - Get a crafting plan for a specific item.
* `Exit` - Exit the program.

#### Items

The items menu has the following options:

* [`Add Item`](#add-item) - Add an item to the program.
* [`Edit Item`](#edit-item) - Edit an item in the program.
* [`Delete Item`](#delete-item) - Delete an item from the program.
* [`Back`](#main-menu) - Return to the main menu.

##### Add Item

To add an item in this menu, the following steps will be followed:

1. Enter the name of the item.
2. Enter the amount of items that will be crafted at once.
3. Enter the machine this item will be crafted in.
4. Enter the crafting recipe for this item (Optional).

When entering the crafting recipe, for each item you will be prompted with the
following:

1. Does the item exist in the program? If yes, select the item from the list. If
  no, add the item to the program. This is recursive, so you can add items that
  don't exist yet.
2. Enter the amount of the item that will be used in the recipe.

If the item does not have a crafting recipe, it will be treated as a raw
material, which will get totalled up in the crafting plan.

##### Edit Item

When entering this menu, you will be presented with a list of all items added to
the program. Select the item you wish to edit, and you will be presented with
the following options:

* `Name` - Edit the name of the item.
* `Amount` - Edit the amount of items that will be crafted at once.
* `Machine` - Edit the machine this item will be crafted in.
* `Recipe` - Edit the crafting recipe for this item.
* `Preferred Recipe` - Edit the preferred crafting recipe for this item. This 
  overrides any preferred machine if one is set and has a recipe for this item.
* `Back` - Return to the items menu.

If you select `Recipe`, you will be prompted to add, edit, or delete items from
the recipe.

##### Delete Item

When entering this menu, you will be presented with a list of all items added to
the program. Select the item you wish to delete, and it will be deleted (after
confirmation).

#### Machines

The machines menu has the following options:

* [`Add Machine`](#add-machine) - Add a machine to the program.
* [`Edit Machine`](#edit-machine) - Edit a machine in the program.
* [`Delete Machine`](#delete-machine) - Delete a machine from the program.
* [`Back`](#main-menu) - Return to the main menu.

##### Add Machine

When you open this menu, you will be prompted to enter the name of the machine.
That is it, you are done.

##### Edit Machine

When entering this menu, you will be presented with a list of all machines added
to the program. Select the machine you wish to edit, and it will ask you for the
new name of the machine. 

After that, it will prompt you for a 'Preference level' for the machine. This is
used to determine which machine to use when crafting items. If an item has
multiple recipes and each recipe has a different machine, the machine with the
highest preference level will be used. If multiple machines have the same
preference level, whichever machine the program grabs first will be used. The 
crafting table and all newly added machines have a default preference level of
0.

This is overrideable on a per-item basis, so if you have a machine that is
better than the one you set here for a specific item, you can set that item to
use that machine instead. See [`Edit Item`](#edit-item) for more information.

##### Delete Machine

When entering this menu, you will be presented with a list of all machines added
to the program. Select the machine you wish to delete, and it will be deleted
(after confirmation).

#### Crafting

When entering this menu, you will be prompted to enter the name of the item you
wish to craft. If the item exists in the program, it will ask you how many of 
the item you wish to craft. If the item does not exist in the program, you will
be prompted to add it.

Then, you will be presented with a crafting plan for that item.

The crafting plan will show you the total amount of each raw resource you need
to have, then give you a step-by-step guide on how to craft the item.

## License

This project is licensed under the [MIT License](LICENSE).

## Credits

* [PrimeUI](https://github.com/MCJack123/PrimeUI/tree/master) by @MCJack123