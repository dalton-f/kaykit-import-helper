# kaykit-import-helper

A lightweight Godot plugin designed to streamline workflows with KayKit asset packs by automating material extraction and gridmap generation.

## Features

- **Automatic Material Extraction**: Extracts and organizes materials from imported KayKit assets.

- **Gridmap Generation**: Quickly generates Gridmaps from compatible meshes, saving setup time for level building.

- **Texture Fixes**: Automatically change texture compression modes to prevent banding on the models

## Installation

1. Download or clone this repository.
2. Place the plugin folder inside your Godot project’s `addons/` directory: `res://addons/kaykit_import_helper/`
3. Open your project in Godot.
4. Go to **Project → Project Settings → Plugins**.
5. Enable **KayKit Import Helper**.

## Usage

1. Import your KayKit asset pack into your project.
2. Select the relevant assets in the FileSystem dock. (ensure the selected folder name matches the asset pack name)
3. Use the plugin tools (available in the editor interface) to request a reimport
4. The plugin will automatically organize outputs for immediate use.

## Contributing

1. Fork the repository
2. Create a feature branch: git checkout -b feature-name
3. Make your changes and test thoroughly
4. Commit your changes: git commit -am 'Add new feature'
5. Push to the branch: git push origin feature-name
6. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.
