class ToolMenu {
  final String id;
  final String name;
  final String usage;
  final String ide;
  final String language;
  final String description;
  final String image;
  final String picture;

  const ToolMenu(
      {required this.id,
      required this.name,
      required this.usage,
      required this.ide,
      required this.language,
      required this.description,
      required this.image,
      required this.picture});
}

List<ToolMenu> toolMenus = [
  const ToolMenu(
      id: "1",
      name: "SherAcc",
      usage: "Trading",
      ide: "DotNet",
      language: "C#",
      description:
          "SherAcc is accounting software developed by Shersoft software company. This has been developed with aim of simplifying the accounting and bookkeeping efforts for all business. SherAcc can customized to suit any trading or non trading organization and helps in the systematic management of inventory with complete reporting. SherAcc is developed by highly skilled programming professionals with considerable suggestions from experts in business,accounting and taxation.",
      image: "assets/logo.png",
      picture: "assets/wallpaper_blue.png"),
  const ToolMenu(
      id: "2",
      name: "SherTex",
      usage: "Textiles",
      ide: "DotNet",
      language: "C#",
      description:
          "SherTex is highly reliable software solution for textiles business. It deals both accounting and inventory aspects. SherTex is developed by SherSoft Software Company with help of experts in textile business.",
      image: "assets/logo.png",
      picture: "assets/wallpaper_blue.png"),
  const ToolMenu(
      id: "3",
      name: "SherPharma",
      usage: "Medical",
      ide: "VB6",
      language: "VB",
      description:
          "SherPharma is a typical software solution to deal with all the transaction in pharmacy management. SherPharma is developed by SherSoft software company with the help of expert in pharmacy business",
      image: "assets/logo.png",
      picture: "assets/wallpaper_blue.png"),
  const ToolMenu(
      id: "4",
      name: "SherGold",
      usage: "Jewelry",
      ide: "VB6",
      language: "VB",
      description:
          "SherGold is a software solution developed by SherSoft software company. SherGold is completely dedicated to ease the operations of a gold business. SherGold is developed with the assistance of experts in gold business",
      image: "assets/logo.png",
      picture: "assets/wallpaper_blue.png"),
  const ToolMenu(
      id: "5",
      name: "SherAccApp",
      usage: "Android",
      ide: "IDE",
      language: "Java",
      description:
          "SherAccApp is accounting software developed by Shersoft software company. This has been developed with aim of simplifying the accounting and bookkeeping efforts for all business on mobile. SherAcc can customized to suit any trading or non trading organization and helps in the systematic management of inventory with reporting. SherAcc is developed by highly skilled programming professionals with considerable suggestions from experts in business",
      image: "assets/logo.png",
      picture: "assets/wallpaper_blue.png"),
  const ToolMenu(
      id: "6",
      name: "Others",
      usage: "Application",
      ide: "Feature",
      language: "Dart,React",
      description:
          "SherSoft also Develop Customized Software for Computer,Web and Mobile. There we are using latest framework and technology. Now we are using Java, VB, C#, Flutter , React, Python and APIs.",
      image: "assets/logo.png",
      picture: "assets/wallpaper_blue.png"),
];
