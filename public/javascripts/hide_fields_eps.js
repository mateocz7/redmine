// Script para ocultar campos específicos para usuarios con rol "Usuario Eps"
// Se ejecuta en la página de creación de issues

(function() {
  'use strict';
  
  console.log('🔒 Script de ocultación de campos para Usuario Eps: INICIANDO');
  
  // Función para verificar si estamos en la página de creación de issues
  function isNewIssuePage() {
    const url = window.location.pathname;
    return url.includes('/issues/new') || url.match(/\/projects\/[^\/]+\/issues\/new/);
  }
  
  // Función para obtener el login del usuario actual
  function getCurrentUserLogin() {
    // Método 1: Buscar en #loggedas
    const loggedAs = document.getElementById('loggedas');
    if (loggedAs) {
      const loggedText = loggedAs.textContent || '';
      // Buscar patrones como "Conectado como usuarioexterno" o "Logged in as usuarioexterno"
      const loginMatch = loggedText.match(/(?:como|as)\s+([^\s]+)/i);
      if (loginMatch && loginMatch[1]) {
        console.log('🔒 Login detectado en #loggedas:', loginMatch[1]);
        return loginMatch[1];
      }
    }
    
    // Método 2: Buscar en el menú de usuario
    const userMenu = document.querySelector('#top-menu a.user, .user a, [href*="/users/"]');
    if (userMenu) {
      const href = userMenu.getAttribute('href') || '';
      const userMatch = href.match(/\/users\/(\d+)/);
      if (userMatch) {
        // Si tenemos el ID, podemos hacer una petición para obtener el login
        return null; // Se obtendrá mediante API
      }
    }
    
    // Método 3: Buscar en el header o top-menu
    const topMenu = document.getElementById('top-menu');
    if (topMenu) {
      const links = topMenu.querySelectorAll('a');
      for (let link of links) {
        const href = link.getAttribute('href') || '';
        if (href.includes('/users/') || href.includes('/my/account')) {
          const text = link.textContent || '';
          if (text.trim() && !text.includes('Terminar') && !text.includes('Log out')) {
            console.log('🔒 Posible login detectado en top-menu:', text.trim());
            return text.trim();
          }
        }
      }
    }
    
    return null;
  }
  
  // Función para verificar si el usuario tiene el rol "Usuario Eps"
  function hasEpsRole(login) {
    // Usuarios conocidos con rol "Usuario Eps"
    const epsUsers = ['usuarioexterno'];
    
    if (login && epsUsers.includes(login.toLowerCase())) {
      console.log('🔒 Usuario con rol "Usuario Eps" detectado por login:', login);
      return true;
    }
    
    return false;
  }
  
  // Función para obtener el rol del usuario actual
  function getUserRole() {
    // Método 1: Verificar por login del usuario
    const userLogin = getCurrentUserLogin();
    if (userLogin && hasEpsRole(userLogin)) {
      return 'Usuario Eps';
    }
    
    // Método 2: Buscar en el HTML si hay información del rol
    const roleElements = document.querySelectorAll('[data-role], .role, [class*="role"]');
    for (let elem of roleElements) {
      const roleText = elem.textContent || '';
      if (roleText.includes('Usuario Eps') || roleText.includes('EPS')) {
        console.log('🔒 Rol detectado en HTML:', roleText);
        return 'Usuario Eps';
      }
    }
    
    // Método 3: Buscar en el contenido de la página
    const bodyText = document.body.textContent || '';
    if (bodyText.includes('Usuario Eps')) {
      console.log('🔒 Rol "Usuario Eps" encontrado en el contenido de la página');
      return 'Usuario Eps';
    }
    
    return null; // Retornamos null para indicar que no se pudo determinar
  }
  
  // Función para verificar el rol mediante AJAX
  function checkUserRoleViaAPI(callback) {
    // Obtener el ID del proyecto desde la URL
    const urlMatch = window.location.pathname.match(/\/projects\/([^\/]+)\/issues\/new/);
    if (!urlMatch) {
      callback(null);
      return;
    }
    
    const projectIdentifier = urlMatch[1];
    
    // Intentar obtener información del usuario actual desde la API
    fetch('/users/current.json', {
      credentials: 'same-origin',
      headers: {
        'Accept': 'application/json'
      }
    })
    .then(response => {
      if (!response.ok) {
        throw new Error('No se pudo obtener información del usuario');
      }
      return response.json();
    })
    .then(data => {
      if (data.user) {
        const userLogin = data.user.login;
        
        // Verificar si el login corresponde a un usuario Eps
        if (hasEpsRole(userLogin)) {
          callback('Usuario Eps');
          return;
        }
        
        const userId = data.user.id;
        
        // Obtener los miembros del proyecto para verificar el rol
        fetch(`/projects/${projectIdentifier}/memberships.json`, {
          credentials: 'same-origin',
          headers: {
            'Accept': 'application/json'
          }
        })
        .then(response => response.json())
        .then(membersData => {
          if (membersData.memberships) {
            const userMembership = membersData.memberships.find(m => m.user && m.user.id === userId);
            if (userMembership && userMembership.roles) {
              const hasEpsRole = userMembership.roles.some(r => r.name === 'Usuario Eps');
              callback(hasEpsRole ? 'Usuario Eps' : null);
              return;
            }
          }
          callback(null);
        })
        .catch(() => callback(null));
      } else {
        callback(null);
      }
    })
    .catch(() => {
      // Si falla la API, usar método alternativo
      callback(null);
    });
  }
  
  // Función para ocultar los campos específicos
  function hideFieldsForEpsUser() {
    console.log('🔒 Ocultando campos para usuario Eps...');
    
    // Campo 1: "Asignado a" (Assigned to)
    // Buscar por label, id, o name
    const assignedToLabels = document.querySelectorAll('label');
    for (let label of assignedToLabels) {
      const labelText = label.textContent || '';
      if (labelText.includes('Asignado a') || labelText.includes('Assigned to')) {
        const fieldContainer = label.closest('p, div, fieldset, .splitcontentleft, .splitcontentright');
        if (fieldContainer) {
          fieldContainer.style.display = 'none';
          console.log('🔒 Campo "Asignado a" ocultado');
        }
        
        // También buscar el input/select directamente
        const inputId = label.getAttribute('for');
        if (inputId) {
          const input = document.getElementById(inputId);
          if (input) {
            const inputContainer = input.closest('p, div, fieldset');
            if (inputContainer) {
              inputContainer.style.display = 'none';
            }
          }
        }
      }
    }
    
    // Buscar directamente por id o name
    const assignedToInput = document.querySelector('#issue_assigned_to_id, [name="issue[assigned_to_id]"], #issue_assigned_to_id + *');
    if (assignedToInput) {
      const container = assignedToInput.closest('p, div, fieldset, .splitcontentleft, .splitcontentright');
      if (container) {
        container.style.display = 'none';
        console.log('🔒 Campo "Asignado a" ocultado (por ID/name)');
      }
    }
    
    // Campo 2: Sección completa de "Tarea/Time Details" (splitcontentright)
    // Esta sección contiene: Tarea padre, Fecha inicio, Fecha fin, Tiempo estimado, % Realizado
    const rightColumn = document.querySelector('.splitcontentright');
    if (rightColumn) {
      // Ocultar campos específicos dentro de splitcontentright
      const fieldsToHide = [
        { label: 'Tarea padre', ids: ['#issue_parent_issue_id', '[name="issue[parent_issue_id]"]'] },
        { label: 'Fecha de inicio', ids: ['#issue_start_date', '[name="issue[start_date]"]'] },
        { label: 'Fecha fin', ids: ['#issue_due_date', '[name="issue[due_date]"]'] },
        { label: 'Tiempo estimado', ids: ['#issue_estimated_hours', '[name="issue[estimated_hours]"]'] },
        { label: '% Realizado', ids: ['#issue_done_ratio', '[name="issue[done_ratio]"]'] }
      ];
      
      fieldsToHide.forEach(field => {
        field.ids.forEach(selector => {
          const element = document.querySelector(selector);
          if (element) {
            // Buscar el párrafo o contenedor padre que contiene el label y el input
            let container = element.closest('p');
            if (!container) {
              container = element.closest('div');
            }
            if (!container) {
              container = element.parentElement;
            }
            
            if (container) {
              container.style.display = 'none';
              console.log(`🔒 Campo "${field.label}" ocultado`);
            }
          }
        });
        
        // También buscar por label
        const labels = document.querySelectorAll('label');
        for (let label of labels) {
          const labelText = label.textContent || '';
          if (labelText.includes(field.label)) {
            const container = label.closest('p, div');
            if (container) {
              container.style.display = 'none';
              console.log(`🔒 Campo "${field.label}" ocultado (por label)`);
            }
          }
        }
      });
    }
    
    console.log('🔒 Campos ocultados exitosamente');
  }
  
  // Función principal
  function init() {
    // Verificar si estamos en la página correcta
    if (!isNewIssuePage()) {
      console.log('🔒 No es la página de creación de issues, saliendo');
      return;
    }
    
    console.log('🔒 Página de creación de issues detectada');
    
    // Intentar obtener el rol del usuario
    let userRole = getUserRole();
    
    // Si no se pudo determinar el rol, intentar con AJAX
    if (!userRole) {
      console.log('🔒 Intentando obtener rol mediante API...');
      checkUserRoleViaAPI(function(role) {
        if (role === 'Usuario Eps') {
          console.log('🔒 Usuario con rol "Usuario Eps" confirmado mediante API');
          hideFieldsForEpsUser();
        } else {
          console.log('🔒 Usuario NO tiene rol "Usuario Eps"');
        }
      });
    } else if (userRole === 'Usuario Eps') {
      console.log('🔒 Usuario con rol "Usuario Eps" detectado');
      hideFieldsForEpsUser();
    } else {
      console.log('🔒 Usuario NO tiene rol "Usuario Eps"');
    }
  }
  
  // Ejecutar cuando el DOM esté listo
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', function() {
      setTimeout(init, 100);
      setTimeout(init, 500);
      setTimeout(init, 1000);
    });
  } else {
    setTimeout(init, 100);
    setTimeout(init, 500);
    setTimeout(init, 1000);
  }
  
  // También ejecutar cuando la página esté completamente cargada
  window.addEventListener('load', function() {
    setTimeout(init, 200);
    setTimeout(init, 1000);
  });
  
  // Observar cambios en el DOM por si los campos se cargan dinámicamente
  const observer = new MutationObserver(function(mutations) {
    let shouldCheck = false;
    mutations.forEach(function(mutation) {
      if (mutation.addedNodes.length > 0) {
        shouldCheck = true;
      }
    });
    if (shouldCheck) {
      setTimeout(init, 100);
    }
  });
  
  // Iniciar observación
  if (document.body) {
    observer.observe(document.body, {
      childList: true,
      subtree: true
    });
  }
  
})();
