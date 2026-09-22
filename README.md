
# Shader2Post

Lets you convert shaders to Minecraft post effects easily



## Setup

Install my-project with npm

1.Launch Minecraft with the mod installed.

2.Open the resource pack folder you will find there a folder called shadertoy_input

3.Create a new folder inside with the name of your posteffect

4.Then you need the code of the shaders you want to use (You can find it on www.shadertoy.com)

5.Create a file named **image.glsl** and a file named **buffer_a.glsl** if your shader has a buffer (Currently this project doesn't support multiple buffers like buffer_b,buffer_c)

6.When you added all the shaders you want ,you can run a command
   `/shadertoy convert` the converter should run without any issues (if you have any report it in the issues tab)

7.Enable the resource pack in the settings

8.Then you can turn on your posteffect using `/posteffect add @p <name of your posteffect> ` **Kepp in mind that some shaders might be copyrighted and you cannot distribute them**

**This project is still in alpha version so there might be a lot of graphical ,lighting or loading bugs if you find any please report them in the issues page.**


 
