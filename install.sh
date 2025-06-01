#!/bin/bash
# Script d'installation dotfiles - Configuration Mac/WSL uniforme
# Objectif : Reproduire l'environnement Oh My Zsh + Starship + configs personnalisées

set -e  # Arrêter le script en cas d'erreur

# Couleurs pour les messages
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Fonction utilitaire pour afficher les messages
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Détecter le système d'exploitation
detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    elif [[ "$OSTYPE" == "linux"* ]]; then
        if grep -q "Microsoft" /proc/version 2>/dev/null; then
            echo "wsl"
        else
            echo "linux"
        fi
    else
        echo "unknown"
    fi
}

# Installer les dépendances selon l'OS
install_dependencies() {
    local os_type=$1
    
    log_info "Installation des dépendances pour $os_type..."
    
    case $os_type in
        "macos")
            # Vérifier si Homebrew est installé
            if ! command -v brew &> /dev/null; then
                log_info "Installation de Homebrew..."
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            fi
            
            # Installer Starship si nécessaire
            if ! command -v starship &> /dev/null; then
                log_info "Installation de Starship..."
                brew install starship
            fi
            ;;
            
        "wsl"|"linux")
            # Installer Starship si nécessaire
            if ! command -v starship &> /dev/null; then
                log_info "Installation de Starship..."
                curl -sS https://starship.rs/install.sh | sh
            fi
            ;;
    esac
}

# Installer Oh My Zsh si nécessaire
install_oh_my_zsh() {
    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        log_info "Installation d'Oh My Zsh..."
        
        # Sauvegarder le .zshrc existant s'il existe
        if [ -f "$HOME/.zshrc" ]; then
            log_warning "Sauvegarde de l'ancien .zshrc vers .zshrc.backup"
            cp "$HOME/.zshrc" "$HOME/.zshrc.backup"
        fi
        
        # Installer Oh My Zsh (mode non-interactif)
        RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
        
        log_success "Oh My Zsh installé avec succès"
    else
        log_info "Oh My Zsh déjà installé"
    fi
}

# Créer les liens symboliques pour les fichiers de configuration
create_symlinks() {
    local dotfiles_dir="$HOME/dotfiles"
    
    log_info "Création des liens symboliques..."
    
    # Lien pour .gitconfig
    if [ -f "$dotfiles_dir/git/.gitconfig" ]; then
        ln -sf "$dotfiles_dir/git/.gitconfig" "$HOME/.gitconfig"
        log_success "Lien symbolique créé : .gitconfig"
    fi
    
    # Configuration .zshrc
    if [ -f "$dotfiles_dir/shell/.zshrc_complete" ]; then
        ln -sf "$dotfiles_dir/shell/.zshrc_complete" "$HOME/.zshrc"
        log_success "Lien symbolique créé : .zshrc"
    fi
    
    # Créer le répertoire .config si nécessaire
    mkdir -p "$HOME/.config"
    
    # Configuration Starship (si elle existe)
    if [ -f "$dotfiles_dir/starship.toml" ]; then
        ln -sf "$dotfiles_dir/starship.toml" "$HOME/.config/starship.toml"
        log_success "Lien symbolique créé : starship.toml"
    fi
}

# Installer NVM si nécessaire (pour la compatibilité avec la config WSL)
install_nvm() {
    if [ ! -d "$HOME/.nvm" ]; then
        log_info "Installation de NVM..."
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
        log_success "NVM installé avec succès"
    else
        log_info "NVM déjà installé"
    fi
}

# Vérifier que nous sommes dans le bon répertoire
check_dotfiles_directory() {
    if [ ! -f "$(pwd)/install.sh" ] || [ ! -d "$(pwd)/.git" ]; then
        log_error "Ce script doit être exécuté depuis le répertoire dotfiles"
        log_info "Usage: cd ~/dotfiles && ./install.sh"
        exit 1
    fi
}

# Afficher un résumé des actions qui vont être effectuées
show_installation_plan() {
    local os_type=$1
    
    echo ""
    echo "==================== PLAN D'INSTALLATION ===================="
    echo "Système détecté    : $os_type"
    echo "Répertoire dotfiles: $(pwd)"
    echo ""
    echo "Actions qui vont être effectuées :"
    echo "  1. Installation des dépendances ($os_type)"
    echo "  2. Installation d'Oh My Zsh (si nécessaire)"
    echo "  3. Installation de NVM (si nécessaire)"
    echo "  4. Création des liens symboliques"
    echo "  5. Configuration terminée"
    echo "=============================================================="
    echo ""
    
    read -p "Voulez-vous continuer ? (y/N) " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Installation annulée par l'utilisateur"
        exit 0
    fi
}

# Fonction principale
main() {
    echo ""
    echo "🚀 Installation des dotfiles - Configuration unifiée Mac/WSL"
    echo ""
    
    # Vérifications préliminaires
    check_dotfiles_directory
    
    # Détecter l'OS
    local os_type=$(detect_os)
    
    if [ "$os_type" = "unknown" ]; then
        log_error "Système d'exploitation non supporté"
        exit 1
    fi
    
    # Afficher le plan et demander confirmation
    show_installation_plan "$os_type"
    
    # Procéder à l'installation
    log_info "Début de l'installation..."
    
    install_dependencies "$os_type"
    install_oh_my_zsh
    install_nvm
    create_symlinks
    
    echo ""
    log_success "✅ Installation terminée avec succès !"
    echo ""
    echo "Pour finaliser la configuration :"
    echo "  1. Redémarrez votre terminal ou exécutez : source ~/.zshrc"
    echo "  2. Vérifiez que Starship fonctionne correctement"
    echo "  3. Vos aliases personnalisés sont disponibles via .bashrc_common"
    echo ""
    echo "🎉 Votre environnement est maintenant synchronisé et optimisé !"
}

# Exécuter le script principal
main "$@"
