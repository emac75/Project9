const SERVER = 'emac75.ddns.net'
const PORT = 5556;

async function fetchUsers() {
    try {
        const response = await fetch(`http://${SERVER}:${PORT}/users`);
        const users = await response.json();
        const userList = document.getElementById('userList');
        userList.innerHTML = '';
        users.forEach(user => {
            const userDiv = document.createElement('div');
            userDiv.classList.add('user');
            userDiv.innerHTML = `
                <div class="userDetails">
                    <span>User ID: ${user.id}</span>
                    <span>Username: ${user.username}</span>
                    <span>Email: ${user.email}</span>
                    <span>Admin: ${user.admin}</span>

                </div>
                <div class="userActions">
                    <button class="editButton" onclick="editUser('${user.id}', '${user.username}', '${user.email}', '${user.admin}')">Editar</button>
                    <button class="deleteButton" onclick="confirmDelete('${user.id}')">Apagar utilizador</button>
                    <button class="deleteButton" onclick="deleteFields('${user.id}')">Apagar dados biométricos</button>
                </div>
            `;
            userList.appendChild(userDiv);
        });
    } catch (error) {
        console.error('Error fetching users', error);
    }
}

function editUser(userId, username, email, admin) {
    const modal = document.getElementById('editUserModal');
    const editNameInput = document.getElementById('editName');
    const editEmailInput = document.getElementById('editEmail');
    const editPasswordInput = document.getElementById('editPassword');
    const editAdminInput = document.getElementById('editAdmin');

    editNameInput.value = username;
    editEmailInput.value = email;
    editAdminInput.checked = admin === "true";

    modal.style.display = 'block';

    const confirmButton = document.getElementById('confirmButton');
    confirmButton.onclick = async function(event) {
        event.preventDefault();
        try {
            await fetch(`http://${SERVER}:${PORT}/users/${userId}`, {
                method: 'PUT',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({
                    username: editNameInput.value,
                    email: editEmailInput.value,
                    password: editPasswordInput.value,
                    admin: editAdminInput.checked
                })
            });
            modal.style.display = 'none';
            editNameInput.value = '';
            editEmailInput.value = '';
            editPasswordInput.value = '';
            editAdminInput.checked = false;
            fetchUsers();
        } catch (error) {
            console.error('Error updating user', error);
        }
    };

    const cancelButton = document.getElementById('cancelButton');
    cancelButton.onclick = function() {
        modal.style.display = 'none';
    };

}

async function deleteFields(userId) {
    const isConfirmed = confirm('Tem a certeza de que pretende apagar os dados biométricos deste utilizador?');
    if (!isConfirmed) {
      return;
    }
  
    try {
      const response = await fetch(`http://${SERVER}:${PORT}/users/${userId}/delete-fields`, {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json'
        }
      });
  
      if (response.ok) {
        const result = await response.text();
      } else {
        console.error('Failed to delete fields:', response.statusText);
      }
    } catch (error) {
      console.error('Error:', error);
    }
}
  

function confirmDelete(userId) {
    const confirmation = confirm('Tem a certeza de que pretende apagar este utilizador?');
    if (confirmation) {
        deleteUser(userId);
    }
}

async function deleteUser(userId) {
    try {
        await fetch(`http://${SERVER}:${PORT}/users/${userId}`, {
            method: 'DELETE'
        });
        fetchUsers();
    } catch (error) {
        console.error('Error deleting user', error);
    }
}

function logout() {
    sessionStorage.removeItem('auth');
    window.location.href = 'login.html';
}

window.onclick = function(event) {
    const modal = document.getElementById('editUserModal');
    if (event.target == modal) {
        modal.style.display = 'none';
    }
}


window.onload = function() {
    const authValue = sessionStorage.getItem('auth');
    if (authValue) {
        fetchUsers();  
    } else {
        window.location.href = 'login.html';
    }
};
