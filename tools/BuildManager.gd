@tool
extends EditorScript

## Production-ready build and deployment manager

const BUILD_CONFIGS = {
	"web": {
		"export_preset": "Web",
		"output_path": "build/web/index.html",
		"features": ["web", "gl_compatibility"],
		"optimization": "size",
		"debug": false
	},
	"windows": {
		"export_preset": "Windows Desktop",
		"output_path": "build/windows/glitch-dimension.exe",
		"features": ["windows", "pc"],
		"optimization": "speed",
		"debug": false
	},
	"linux": {
		"export_preset": "Linux/X11",
		"output_path": "build/linux/glitch-dimension.x86_64",
		"features": ["linux", "pc"],
		"optimization": "speed",
		"debug": false
	},
	"macos": {
		"export_preset": "macOS",
		"output_path": "build/macos/glitch-dimension.zip",
		"features": ["macos", "pc"],
		"optimization": "speed",
		"debug": false
	}
}

const VERSION_FILE = "res://data/version.json"
const CHANGELOG_FILE = "CHANGELOG.md"

func _run():
	print("🚀 Build Manager - Production Build System")
	print("==========================================")
	
	var args = OS.get_cmdline_args()
	var command = _get_command_from_args(args)
	
	match command:
		"build":
			var platform = _get_platform_from_args(args)
			_build_platform(platform)
		"build-all":
			_build_all_platforms()
		"version":
			_update_version()
		"clean":
			_clean_build_directory()
		"validate":
			_validate_project()
		"package":
			_package_builds()
		_:
			_show_help()

func _get_command_from_args(args: PackedStringArray) -> String:
	for arg in args:
		if arg.begins_with("--build-"):
			return arg.substr(2)
		elif arg in ["--build-all", "--version", "--clean", "--validate", "--package"]:
			return arg.substr(2)
	return ""

func _get_platform_from_args(args: PackedStringArray) -> String:
	for arg in args:
		if arg.begins_with("--build-"):
			return arg.substr(8)  # Remove "--build-"
	return "web"  # Default platform

func _build_platform(platform: String):
	print("🎯 Building for platform: ", platform)
	
	if not platform in BUILD_CONFIGS:
		print("❌ Unknown platform: ", platform)
		print("Available platforms: ", BUILD_CONFIGS.keys())
		return
	
	var config = BUILD_CONFIGS[platform]
	
	# Pre-build validation
	if not _validate_build_requirements(platform):
		print("❌ Build requirements not met")
		return
	
	# Update version info
	_update_build_info(platform)
	
	# Perform the build
	var success = _execute_build(config)
	
	if success:
		print("✅ Build completed successfully for ", platform)
		_post_build_tasks(platform, config)
	else:
		print("❌ Build failed for ", platform)

func _build_all_platforms():
	print("🌍 Building for all platforms...")
	
	var failed_builds = []
	
	for platform in BUILD_CONFIGS.keys():
		print("\n" + "=".repeat(50))
		print("Building ", platform, "...")
		print("=".repeat(50))
		
		_build_platform(platform)
		
		# Check if build was successful
		var config = BUILD_CONFIGS[platform]
		if not FileAccess.file_exists(config.output_path):
			failed_builds.append(platform)
	
	print("\n🏁 Build Summary:")
	print("================")
	
	if failed_builds.is_empty():
		print("✅ All builds completed successfully!")
	else:
		print("❌ Failed builds: ", failed_builds)
		print("✅ Successful builds: ", _get_successful_builds())

func _validate_build_requirements(platform: String) -> bool:
	print("🔍 Validating build requirements for ", platform, "...")
	
	var issues = []
	
	# Check export preset exists
	var config = BUILD_CONFIGS[platform]
	var export_presets = EditorInterface.get_export_presets()
	var preset_found = false
	
	for preset in export_presets:
		if preset.get_name() == config.export_preset:
			preset_found = true
			break
	
	if not preset_found:
		issues.append("Export preset not found: " + config.export_preset)
	
	# Check required files exist
	var required_files = [
		"res://project.godot",
		"res://ui/MainMenu.tscn",
		"res://icon.svg"
	]
	
	for file_path in required_files:
		if not FileAccess.file_exists(file_path):
			issues.append("Required file missing: " + file_path)
	
	# Check project settings
	var required_settings = [
		"application/config/name",
		"application/config/version",
		"application/run/main_scene"
	]
	
	for setting in required_settings:
		if not ProjectSettings.has_setting(setting):
			issues.append("Required project setting missing: " + setting)
	
	# Platform-specific checks
	match platform:
		"web":
			if not _check_web_requirements():
				issues.append("Web build requirements not met")
		"windows":
			if not _check_windows_requirements():
				issues.append("Windows build requirements not met")
	
	if not issues.is_empty():
		print("❌ Validation issues found:")
		for issue in issues:
			print("  - ", issue)
		return false
	
	print("✅ All requirements validated")
	return true

func _check_web_requirements() -> bool:
	# Check web-specific requirements
	var web_files = [
		"res://web/manifest.json",
		"res://web/icon-192.png",
		"res://web/icon-512.png"
	]
	
	for file_path in web_files:
		if not FileAccess.file_exists(file_path):
			print("  Missing web file: ", file_path)
			return false
	
	return true

func _check_windows_requirements() -> bool:
	# Check Windows-specific requirements
	return true  # No specific requirements for now

func _update_build_info(platform: String):
	print("📝 Updating build information...")
	
	var build_info = {
		"version": ProjectSettings.get_setting("application/config/version", "1.0.0"),
		"build_date": Time.get_datetime_string_from_system(),
		"platform": platform,
		"godot_version": Engine.get_version_info(),
		"commit_hash": _get_git_commit_hash(),
		"build_number": _get_next_build_number()
	}
	
	# Save build info
	var file = FileAccess.open("res://data/build_info.json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(build_info, "\t"))
		file.close()
		print("✅ Build info updated")

func _get_git_commit_hash() -> String:
	# Try to get git commit hash
	var output = []
	OS.execute("git", ["rev-parse", "--short", "HEAD"], output)
	if output.size() > 0:
		return output[0].strip_edges()
	return "unknown"

func _get_next_build_number() -> int:
	var build_file = "user://build_number.txt"
	var build_number = 1
	
	if FileAccess.file_exists(build_file):
		var file = FileAccess.open(build_file, FileAccess.READ)
		if file:
			build_number = file.get_as_text().to_int() + 1
			file.close()
	
	# Save incremented build number
	var file = FileAccess.open(build_file, FileAccess.WRITE)
	if file:
		file.store_string(str(build_number))
		file.close()
	
	return build_number

func _execute_build(config: Dictionary) -> bool:
	print("🔨 Executing build...")
	
	# Ensure output directory exists
	var output_dir = config.output_path.get_base_dir()
	if not DirAccess.dir_exists_absolute(output_dir):
		DirAccess.make_dir_recursive_absolute(output_dir)
	
	# Build command
	var args = [
		"--headless",
		"--export-release",
		config.export_preset,
		config.output_path
	]
	
	print("Command: godot ", " ".join(args))
	
	var exit_code = OS.execute("godot", args)
	
	if exit_code == 0:
		print("✅ Export completed successfully")
		return true
	else:
		print("❌ Export failed with exit code: ", exit_code)
		return false

func _post_build_tasks(platform: String, config: Dictionary):
	print("🔧 Running post-build tasks...")
	
	# Verify build output exists
	if not FileAccess.file_exists(config.output_path):
		print("❌ Build output not found: ", config.output_path)
		return
	
	# Platform-specific post-build tasks
	match platform:
		"web":
			_post_build_web(config)
		"windows":
			_post_build_windows(config)
		"linux":
			_post_build_linux(config)
		"macos":
			_post_build_macos(config)
	
	# Generate build report
	_generate_build_report(platform, config)
	
	print("✅ Post-build tasks completed")

func _post_build_web(config: Dictionary):
	print("🌐 Web post-build tasks...")
	
	# Copy additional web files
	var web_files = [
		"res://web/manifest.json",
		"res://web/icon-192.png",
		"res://web/icon-512.png"
	]
	
	var output_dir = config.output_path.get_base_dir()
	
	for file_path in web_files:
		if FileAccess.file_exists(file_path):
			var filename = file_path.get_file()
			var dest_path = output_dir + "/" + filename
			
			var source = FileAccess.open(file_path, FileAccess.READ)
			var dest = FileAccess.open(dest_path, FileAccess.WRITE)
			
			if source and dest:
				dest.store_buffer(source.get_buffer(source.get_length()))
				source.close()
				dest.close()
				print("  Copied: ", filename)

func _post_build_windows(config: Dictionary):
	print("🪟 Windows post-build tasks...")
	# Add Windows-specific tasks here

func _post_build_linux(config: Dictionary):
	print("🐧 Linux post-build tasks...")
	# Add Linux-specific tasks here

func _post_build_macos(config: Dictionary):
	print("🍎 macOS post-build tasks...")
	# Add macOS-specific tasks here

func _generate_build_report(platform: String, config: Dictionary):
	var report = {
		"platform": platform,
		"build_time": Time.get_datetime_string_from_system(),
		"output_path": config.output_path,
		"file_size": _get_file_size(config.output_path),
		"success": FileAccess.file_exists(config.output_path)
	}
	
	var report_path = "build/reports/" + platform + "_build_report.json"
	
	# Ensure reports directory exists
	if not DirAccess.dir_exists_absolute("build/reports"):
		DirAccess.make_dir_recursive_absolute("build/reports")
	
	var file = FileAccess.open(report_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(report, "\t"))
		file.close()
		print("📊 Build report saved: ", report_path)

func _get_file_size(file_path: String) -> int:
	if FileAccess.file_exists(file_path):
		var file = FileAccess.open(file_path, FileAccess.READ)
		if file:
			var size = file.get_length()
			file.close()
			return size
	return 0

func _get_successful_builds() -> Array:
	var successful = []
	for platform in BUILD_CONFIGS.keys():
		var config = BUILD_CONFIGS[platform]
		if FileAccess.file_exists(config.output_path):
			successful.append(platform)
	return successful

func _clean_build_directory():
	print("🧹 Cleaning build directory...")
	
	if DirAccess.dir_exists_absolute("build"):
		_remove_directory_recursive("build")
		print("✅ Build directory cleaned")
	else:
		print("ℹ️ Build directory doesn't exist")

func _remove_directory_recursive(path: String):
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		while file_name != "":
			var full_path = path + "/" + file_name
			
			if dir.current_is_dir():
				_remove_directory_recursive(full_path)
			else:
				dir.remove(file_name)
			
			file_name = dir.get_next()
		
		dir.remove(path)

func _update_version():
	print("📋 Version management...")
	# Implementation for version updates
	pass

func _validate_project():
	print("✅ Project validation...")
	# Implementation for project validation
	pass

func _package_builds():
	print("📦 Packaging builds...")
	# Implementation for packaging
	pass

func _show_help():
	print("🚀 Glitch Dimension Build Manager")
	print("=================================")
	print("")
	print("Usage: godot --script tools/BuildManager.gd -- [command]")
	print("")
	print("Commands:")
	print("  --build-web       Build for web platform")
	print("  --build-windows   Build for Windows")
	print("  --build-linux     Build for Linux")
	print("  --build-macos     Build for macOS")
	print("  --build-all       Build for all platforms")
	print("  --clean           Clean build directory")
	print("  --validate        Validate project")
	print("  --version         Update version")
	print("  --package         Package builds")
	print("")
	print("Examples:")
	print("  godot --script tools/BuildManager.gd -- --build-web")
	print("  godot --script tools/BuildManager.gd -- --build-all")