#!/bin/bash

# Fadocx Build Script - Interactive Menu (arm64-only)
# Supports beta and prod flavors with release/debug builds

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Helper functions
print_header() {
    clear
    echo ""
    echo -e "${BLUE}${BOLD}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}${BOLD}║${NC}  Fadocx Build Script (arm64-only)                          ${BLUE}${BOLD}║${NC}"
    echo -e "${BLUE}${BOLD}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_section() {
    echo -e "\n${CYAN}${BOLD}▶ $1${NC}"
}

print_command() {
    echo -e "${YELLOW}$ $1${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${CYAN}ℹ $1${NC}"
}

print_option() {
    local num=$1
    local title=$2
    local desc=$3
    local pkg=$4
    local badge=$5
    
    printf "  ${GREEN}${BOLD}%d${NC}  %-40s %b\n" "$num" "$title" "$badge"
    printf "      └─ Package: ${CYAN}%s${NC}\n" "$pkg"
    printf "      └─ %s\n" "$desc"
    echo ""
}

# Get connected devices
get_devices() {
    adb devices | grep -v "List of attached devices" | grep "device$" | awk '{print $1}'
}

# Get APK size (consistent reporting)
get_apk_size() {
    local apk_path=$1
    if [ -f "$apk_path" ]; then
        ls -lh "$apk_path" | awk '{print $5}'
    fi
}

# Main menu
show_main_menu() {
    print_header
    
    echo -e "${BOLD}${GREEN}PRODUCTION BUILDS${NC}"
    echo ""
    
    print_option "1" "Build & Install Prod (Release)" "Optimized, minified (~346MB)" "com.fadseclab.fadocx" "${GREEN}[INSTALL]${NC}"
    print_option "2" "Build Prod (Release Only)" "Build without installing" "com.fadseclab.fadocx" "${CYAN}[BUILD]${NC}"
    
    echo -e "${BOLD}${GREEN}BETA BUILDS${NC}"
    echo ""
    
    print_option "3" "Build & Install Beta (Release)" "Optimized, minified (~346MB)" "com.fadseclab.fadocx.beta" "${GREEN}[INSTALL]${NC}"
    print_option "4" "Build Beta (Release Only)" "Build without installing" "com.fadseclab.fadocx.beta" "${CYAN}[BUILD]${NC}"
    
    echo -e "${BOLD}${YELLOW}DEVELOPMENT${NC}"
    echo ""
    
    print_option "5" "Dev: Run Prod (Debug)" "Hot reload, live debugging" "com.fadseclab.fadocx" "${YELLOW}[RUN]${NC}"
    print_option "6" "Dev: Run Beta (Debug)" "Hot reload, live debugging" "com.fadseclab.fadocx.beta" "${YELLOW}[RUN]${NC}"
    print_option "7" "Dev: Build Prod (Debug)" "Build without installing (~400MB)" "com.fadseclab.fadocx" "${CYAN}[BUILD]${NC}"
    print_option "8" "Dev: Build Beta (Debug)" "Build without installing (~400MB)" "com.fadseclab.fadocx.beta" "${CYAN}[BUILD]${NC}"
    
    echo -e "${BOLD}${RED}MANAGEMENT${NC}"
    echo ""
    
    printf "  ${GREEN}${BOLD}9${NC}  %-40s\n" "Uninstall Prod"
    printf "      └─ Package: ${CYAN}com.fadseclab.fadocx${NC}\n"
    echo ""
    
    printf "  ${GREEN}${BOLD}0${NC}  %-40s\n" "Uninstall Beta"
    printf "      └─ Package: ${CYAN}com.fadseclab.fadocx.beta${NC}\n"
    echo ""
    
    printf "  ${GREEN}${BOLD}q${NC}  %-40s\n" "Exit"
    echo ""
}

# Build and install function
build_and_install() {
    local flavor=$1
    local build_type=$2
    
    print_section "Building $flavor ($build_type)"
    
    local cmd="flutter build apk --flavor $flavor --$build_type --split-per-abi --target-platform android-arm64"
    print_command "$cmd"
    eval "$cmd"
    
    if [ $? -ne 0 ]; then
        print_error "Build failed"
        return 1
    fi
    
    local apk_path="build/app/outputs/flutter-apk/app-arm64-v8a-${flavor}-${build_type}.apk"
    
    if [ ! -f "$apk_path" ]; then
        print_error "APK not found at $apk_path"
        return 1
    fi
    
    local apk_size=$(get_apk_size "$apk_path")
    print_success "Build complete: $apk_path ($apk_size)"
    
    # Get connected devices
    local devices=$(get_devices)
    if [ -z "$devices" ]; then
        print_error "No devices connected"
        return 1
    fi
    
    # If multiple devices, ask which one
    local device_count=$(echo "$devices" | wc -l)
    if [ "$device_count" -gt 1 ]; then
        print_section "Select device:"
        local i=1
        declare -a device_array
        while IFS= read -r device; do
            device_array[$i]=$device
            echo "  $i) $device"
            ((i++))
        done <<< "$devices"
        
        read -p "Enter device number: " device_choice
        local selected_device=${device_array[$device_choice]}
    else
        local selected_device=$devices
    fi
    
    print_section "Installing on $selected_device"
    local install_cmd="adb -s \"$selected_device\" install -r \"$apk_path\""
    print_command "$install_cmd"
    eval "$install_cmd"
    
    if [ $? -eq 0 ]; then
        print_success "Installation complete"
        return 0
    else
        print_error "Installation failed"
        return 1
    fi
}

# Build only function
build_only() {
    local flavor=$1
    local build_type=$2
    
    print_section "Building $flavor ($build_type)"
    
    local cmd="flutter build apk --flavor $flavor --$build_type --split-per-abi --target-platform android-arm64"
    print_command "$cmd"
    eval "$cmd"
    
    if [ $? -ne 0 ]; then
        print_error "Build failed"
        return 1
    fi
    
    local apk_path="build/app/outputs/flutter-apk/app-arm64-v8a-${flavor}-${build_type}.apk"
    
    if [ ! -f "$apk_path" ]; then
        print_error "APK not found at $apk_path"
        return 1
    fi
    
    local apk_size=$(get_apk_size "$apk_path")
    print_success "Build complete: $apk_path ($apk_size)"
}

# Flutter run function (debug with hot reload)
flutter_run() {
    local flavor=$1
    
    print_section "Running $flavor (debug with hot reload)"
    print_info "Press 'r' to hot reload, 'R' to hot restart, 'q' to quit"
    echo ""
    
    local cmd="flutter run --flavor $flavor"
    print_command "$cmd"
    eval "$cmd"
}

# Uninstall function
uninstall_app() {
    local package_name=$1
    local flavor_name=$2
    
    print_section "Uninstalling $flavor_name ($package_name)"
    
    # Get connected devices
    local devices=$(get_devices)
    if [ -z "$devices" ]; then
        print_error "No devices connected"
        return 1
    fi
    
    # If multiple devices, ask which one
    local device_count=$(echo "$devices" | wc -l)
    if [ "$device_count" -gt 1 ]; then
        print_section "Select device:"
        local i=1
        declare -a device_array
        while IFS= read -r device; do
            device_array[$i]=$device
            echo "  $i) $device"
            ((i++))
        done <<< "$devices"
        
        read -p "Enter device number: " device_choice
        local selected_device=${device_array[$device_choice]}
    else
        local selected_device=$devices
    fi
    
    local cmd="adb -s \"$selected_device\" uninstall $package_name"
    print_command "$cmd"
    eval "$cmd"
    
    if [ $? -eq 0 ]; then
        print_success "Uninstall complete"
        return 0
    else
        print_error "Uninstall failed or app not installed"
        return 1
    fi
}

# Main loop
main() {
    while true; do
        show_main_menu
        read -p "$(echo -e ${BOLD})Enter your choice [0-9, q]:$(echo -e ${NC}) " choice
        
        case $choice in
            1)
                build_and_install "prod" "release"
                ;;
            2)
                build_only "prod" "release"
                ;;
            3)
                build_and_install "beta" "release"
                ;;
            4)
                build_only "beta" "release"
                ;;
            5)
                flutter_run "prod"
                ;;
            6)
                flutter_run "beta"
                ;;
            7)
                build_only "prod" "debug"
                ;;
            8)
                build_only "beta" "debug"
                ;;
            9)
                uninstall_app "com.fadseclab.fadocx" "Prod"
                ;;
            0)
                uninstall_app "com.fadseclab.fadocx.beta" "Beta"
                ;;
            q|Q)
                print_success "Goodbye!"
                exit 0
                ;;
            *)
                print_error "Invalid choice. Please try again."
                ;;
        esac
        
        read -p "$(echo -e ${BOLD})Press Enter to continue...$(echo -e ${NC})"
    done
}

# Run main
main
