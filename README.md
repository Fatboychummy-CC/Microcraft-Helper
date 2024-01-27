# Microcraft Helper

## Installation

This program is available on PineStore!

[![Download on PineStore](https://raster.shields.io/badge/dynamic/json?url=https%3A%2F%2Fpinestore.cc%2Fapi%2Fproject%2F56&query=%24.project.downloads&suffix=%20downloads&logo=data%3Aimage%2Fsvg%2Bxml%3Bbase64%2CPD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0iVVRGLTgiPz4KPHN2ZyB3aWR0aD0iNzYuOTA0IiBoZWlnaHQ9Ijg5LjI5NSIgcHJlc2VydmVBc3BlY3RSYXRpbz0ieE1pZFlNaWQiIHZlcnNpb249IjEuMSIgdmlld0JveD0iMCAwIDc2OS4wNCA4OTIuOTUiIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyI%2BCiA8ZyB0cmFuc2Zvcm09InRyYW5zbGF0ZSgtMTQuNzQgLTQuNjgyNikiIGZpbGw9IiM5YWIyZjIiPgogIDxwYXRoIGQ9Im00MTAgODUxYzAtMTIgMjYtMjEgNTgtMjEgMTUgMCAyMiA0IDE3IDktMTQgMTItNzUgMjItNzUgMTJ6Ii8%2BCiAgPHBhdGggZD0ibTU4NSA3NDJjLTEtNDkgNC03MiAxNi04NSAyMi0yNCAzMC02OCAxNi04Ni0xMi0xNC0yNy0zOS00OC03OC0xMC0xOS05LTI2IDQtNDEgMjItMjQgMjEtNjctMi0xNDQtMjEtNjktMzktMTQ0LTQ4LTE5NS00LTI2LTItMzMgMTEtMzMgMzEgMCAxMTIgMzMgMTQxIDU4IDI4IDIzIDgxIDkyIDcxIDkyLTIgMCA1IDI2IDE2IDU3IDI4IDc5IDI5IDIyNCAzIDMwOC0xMCAzMy0xOSA2Mi0xOSA2NS00IDI2LTEzMiAxNTAtMTU1IDE1MC0zIDAtNi0zMC02LTY4eiIvPgogIDxwYXRoIGQ9Im02OCA2NzNjLTcyLTEwOS03MS0yNzggMy00MjMgMzYtNzEgNjItMTAwIDEyOC0xNDAgNDMtMjcgNjUtMzQgMTE4LTM2IDEwMC00IDk4IDExLTE5IDEzNi0zNCAzNy03OCA4OC05NiAxMTMtMjggMzktMzEgNDgtMjEgNjUgMTEgMTcgNiAyNy0zMyA3OS00MCA1My00NCA2Mi0zMiA3OCAxNyAyMyAxOCA1NyAyIDczLTYgNi0xNCAzMS0xNyA1NC02IDQyLTYgNDItMzMgMXoiLz4KIDwvZz4KIDxnIHRyYW5zZm9ybT0idHJhbnNsYXRlKC0xNC43NCAtNC42ODI2KSIgZmlsbD0iIzU5YTY0ZiI%2BCiAgPHBhdGggZD0ibTM2NSA4MTNjLTUzLTYtMTM5LTMzLTE5Mi02MS02OC0zNS04My02Ny01OC0xMjIgMjYtNTkgNDAtNjcgNzgtNDkgNjggMzMgMTY3IDU4IDI2NiA2OSA1OCA1IDEwNiAxMiAxMDkgMTQgMiAzIDYgMzIgOSA2NSA4IDg1IDAgOTEtMTAxIDkwLTQ0LTEtOTQtNC0xMTEtNnoiLz4KICA8cGF0aCBkPSJtNDEwIDQ1OWMtNjctNy0xNjAtMjktMTk5LTQ4LTI3LTE0LTM0LTM2LTIwLTYzIDIxLTM4IDk3LTEzNiAxNTAtMTkzIDI1LTI3IDU4LTcxIDczLTk3IDI1LTQzIDMxLTQ3IDU0LTQyIDQwIDEwIDQyIDEyIDQyIDUyIDAgMjAgNiA1NyAxNCA4MiAyNCA3MyA1NCAxOTIgNjIgMjM2IDUgMzUgMyA0NS0xNSA2My0yMyAyMy0zNiAyNC0xNjEgMTB6Ii8%2BCiA8L2c%2BCiA8ZyB0cmFuc2Zvcm09InRyYW5zbGF0ZSgtMTQuNzQgLTQuNjgyNikiIGZpbGw9IiM3ZWNiMjUiPgogIDxwYXRoIGQ9Im01NTggNjc0Yy0yLTItNTEtOS0xMDktMTQtMTAyLTExLTIwNC0zNy0yNjQtNjktMTYtOC0zMi0xNC0zNC0xMi00IDMtMzEtNDgtMzEtNjEgMC01IDIxLTMxIDQ2LTU4IDUxLTU0IDcxLTYwIDEzMC0zNSAxOSA4IDgzIDE5IDE0MiAyNSA1OCA2IDEwNyAxMiAxMDcgMTNzMTUgMjYgMzMgNTZjMjcgNDMgMzIgNjMgMzAgOTktMiAzNS04IDQ3LTI1IDUzLTExIDQtMjMgNi0yNSAzeiIvPgogPC9nPgogPGcgdHJhbnNmb3JtPSJ0cmFuc2xhdGUoLTE0Ljc0IC00LjY4MjYpIiBmaWxsPSIjZWNlZGVmIj4KICA8cGF0aCBkPSJtMjYwIDg5MGMtMzQtOC03MC00MS03MC02NSAwLTYtOS0yMC0yMC0zMHMtMjAtMjItMjAtMjctMTMtMjEtMzAtMzVjLTM1LTI5LTQxLTgzLTEzLTEyMiAxNS0yMiAxNS0yNi0xLTU2LTE4LTMzLTE4LTMzIDI3LTkxIDI4LTM2IDQyLTYzIDM2LTY4LTIzLTI1IDktNzggMTIwLTE5NyAzNi0zOCA3Mi04MSA4Mi05NiAxMC0xNCAyNS0zMCAzMy0zNSAzNi0yMCA3IDMyLTUzIDk3LTQ4IDUxLTEyNiAxNTAtMTQ5IDE4OS0xMCAxOC05IDI0IDEwIDQwIDIzIDE5IDIzIDE5LTI5IDcxLTUzIDUyLTUzIDUyLTM4IDgyIDE0IDI4IDE0IDMzLTEwIDc2LTMyIDU3LTIzIDgxIDQ2IDEyMCAzNCAxOSA0OSAzMyA0NSA0Mi0xNCAzNyAzNiA3NSA5OCA3NSAyNSAwIDQwLTcgNTQtMjUgMTgtMjMgMjctMjUgOTUtMjUgOTQgMCAxMDItOCA5My04OS02LTUzLTUtNTkgMTQtNjQgMzItOCAyNi02NC0xNS0xMzItMzUtNTgtMzUtNTgtOS04MiAyMS0xOSAyNC0yOSAxOS01Ni0xMC00Ny00NC0xNzUtNjEtMjI3LTgtMjUtMTQtNjItMTQtODMgMC0yNy01LTM5LTE3LTQzLTEwLTMtMjUtOC0zMy0xMC0xMi00LTEyLTYtMS0xNCAyNy0xNiA1NiA1IDY5IDUxIDM1IDExNyA0MyAxNDggNDYgMTcwIDIgMTMgMTEgNTEgMjEgODQgMjEgNzEgMjEgMTIxIDAgMTQ1LTE0IDE1LTEzIDE5IDUgNDMgMTEgMTQgMjAgMzAgMjAgMzVzNyAxNSAxNSAyMmMyMSAxNyAxNiA3NS0xMCAxMDItMTggMTktMjAgMzItMTcgNzkgNCA1MCAyIDU4LTE5IDcyLTEyIDktNTAgMTktODMgMjMtNDUgNS02NSAxMy04MyAzMi0yNiAyOC05MiAzOC0xNTMgMjJ6Ii8%2BCiA8L2c%2BCiA8ZyB0cmFuc2Zvcm09InRyYW5zbGF0ZSgtMTQuNzQgLTQuNjgyNikiIGZpbGw9IiM3ZTY3NGQiPgogIDxwYXRoIGQ9Im0yNDggODU0Yy0zMC0xNi00Ny01OS0zMC03NiA4LTggMjMtNyA1NCAyIDI0IDcgNjEgMTQgODMgMTcgNTQgNyA1OSAxNSAzNSA0Ni0xOCAyMy0yOSAyNy02OCAyNy0yNi0xLTU5LTctNzQtMTZ6Ii8%2BCiA8L2c%2BCjwvc3ZnPgo%3D&label=PineStore)](https://pinestore.cc/projects/56/microcraft-helper)

You can follow the installation instructions there, or run the following
command:

```
wget run https://raw.githubusercontent.com/Fatboychummy-CC/Microcraft-Helper/main/installer.lua
```

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

## Licenses

This project is licensed under the [MIT License](LICENSE).

This project uses the following libraries:

* [fzy-lua](lib/fzy-lua) - MIT License

## Credits

* [PrimeUI](https://github.com/MCJack123/PrimeUI/tree/master) by @MCJack123
* [fzy_lua](https://github.com/swarn/fzy-lua) by @swarn