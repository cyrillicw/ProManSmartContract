pragma solidity ^0.5.0;
contract ProMan {
	int32 public boardsCount = 0;	
	int32 public boardsCreated = 0;
	int32 public groupsCreated = 0;
	int32 public tasksCreated = 0;
	mapping(int32 => Board) public boards;
	mapping(int32 => Group) public groups;
	mapping(int32 => Task) public tasks;
	mapping(address => User) users;
	
	event boardAdded(
        int32 id
    );
	
	event signedUp(
		bool success
	);
	
	event boardLeft(
		bool left
	);
	
	event boardRemoved(
		bool removed
	);
	
	event groupAdded(
		int32 id
	);
	
	event boardParticipantAdded(
		string nick
	);
	
	event taskParticipantAdded(
		string nick
	);

	event taskAdded(
		int32 id
	);
	
	event txCommited(
		bool commited
	);
	
	struct Board {
		int32 id;
		string title;
		int64 start;
		int64 finish;
		address[] users;
		int32[] groupsId;
		mapping(address => bool) usersSet;
	}
	
	struct User {
		bool valid;
		string nick;
		int32[] boards;
	}
	
	struct Group {
		int32 id;
		string title;
		int32 boardId;
		int32[] tasksId;
	}

	struct Task {
		int32 id;
		string title;
		string description;
		int64 start;
		int64 finish;
		int32 groupId;
		int32 boardId;
		address[] users;
		mapping(address => bool) usersSet;
	}
	
	function addBoard(string memory title) public {
		boards[boardsCreated] = Board(boardsCreated, title, -1, -1, new address[](0), new int32[](0));
		boards[boardsCreated].users.push(msg.sender);
		boards[boardsCreated].usersSet[msg.sender] = true;
		users[msg.sender].boards.push(boardsCreated);
		emit boardAdded(boardsCreated);
		boardsCreated++;
	}
	
	function getUserNick(address user) public view returns(string memory) {
		return users[user].nick;
	}
	
	function addGroup(int32 boardId, string memory title) public {
		require (boards[boardId].usersSet[msg.sender]);
		Group memory group = Group(groupsCreated, title, boardId, new int32[](0));
		boards[boardId].groupsId.push(groupsCreated);
		groups[groupsCreated] = group;
		emit groupAdded(groupsCreated);
		groupsCreated++;
	}

	function addTask(int32 groupId, string memory title) public {
		int32 boardId = groups[groupId].boardId;
		require (boards[boardId].usersSet[msg.sender]);
		Task memory task = Task(tasksCreated, title, "", -1, -1, groupId, boardId, new address[](0));
		groups[groupId].tasksId.push(tasksCreated);
		tasks[tasksCreated] = task;
		emit taskAdded(tasksCreated);
		tasksCreated++;
	}
	
	function setTaskDescription(int32 taskId, string memory description) public {
		int32 boardId = tasks[taskId].boardId;
		require (boards[boardId].usersSet[msg.sender]);
		tasks[taskId].description = description;
		//emit txCommited(true);
	}
	
	function setTaskTitle(int32 taskId, string memory title) public {
		int32 boardId = tasks[taskId].boardId;
		require (boards[boardId].usersSet[msg.sender]);
		tasks[taskId].title = title;
		//emit txCommited(true);
	}

	
	function setTaskGroup(int32 taskId, int32 groupId) public {
		int32 boardId = tasks[taskId].boardId;
		require (boards[boardId].usersSet[msg.sender]);
		removeTaskFromGroup(taskId);
		tasks[taskId].groupId = groupId;
		groups[groupId].tasksId.push(taskId);
		//emit txCommited(true);
	}
	
	function removeTaskFromGroup(int32 taskId) public {
		int32 boardId = tasks[taskId].boardId;
		require (boards[boardId].usersSet[msg.sender]);
		Group storage group = groups[tasks[taskId].groupId];
		bool found = false;
		uint index = 0;
		for (uint i = 0; i < group.tasksId.length; i++) {
			if (group.tasksId[i] == taskId) {
				index = i;
				found = true;
				break;
			}
		}
		if (found) {
			for (uint i = index + 1; i < group.tasksId.length; i++) {
				group.tasksId[i - 1] = group.tasksId[i];
			}
			delete group.tasksId[group.tasksId.length - 1];
			group.tasksId.length--;
		}
	}

	function setTaskStart(int32 taskId, int64 time) public {
		int32 boardId = tasks[taskId].boardId;
		require (boards[boardId].usersSet[msg.sender]);
		tasks[taskId].start = time;
		//emit txCommited(true);
	}
	
	function setTaskFinish (int32 taskId, int64 time) public {
		int32 boardId = tasks[taskId].boardId;
		require (boards[boardId].usersSet[msg.sender]);
		tasks[taskId].finish = time;
		//emit txCommited(true);
	}
	
	function setBoardStart(int32 boardId, int64 time) public {
		require (boards[boardId].usersSet[msg.sender]);
		boards[boardId].start = time;
		//emit txCommited(true);
	}
	
	function setBoardFinish (int32 boardId, int64 time) public {
		require (boards[boardId].usersSet[msg.sender]);
		boards[boardId].finish = time;
		//emit txCommited(true);
	}
	
	function addBoardParticipant(int32 boardId, address user) public {
		require (boards[boardId].usersSet[msg.sender]);
		if (users[user].valid && !boards[boardId].usersSet[user]) {
			boards[boardId].users.push(user);
			boards[boardId].usersSet[user] = true;
			users[user].boards.push(boardId);
			emit boardParticipantAdded(users[user].nick);
		}
		else {
			emit boardParticipantAdded("");
		}
	}
	
	function removeBoardParticipant(int32 boardId, address user) public{
		require (boards[boardId].usersSet[msg.sender]);
		removeTaskUsersOfBoard(boardId, user);
		removeBoardFromUser(user, boardId);
		removeUserFromBoard(user, boardId);
	}
	
	function signIn() public view returns(bool) {
		return users[msg.sender].valid;
	}
	
	function signUp(string memory nick) public {
		if (users[msg.sender].valid == false) {
			users[msg.sender] = User(true, nick, new int32[](0));
			emit signedUp(true);
		
		}
		else {
			emit signedUp(false);
		}
	}
	
	/*function getBoardCards() public view returns(int32[] memory, string[] memory, int64[] memory, int64[] memory){
		int32[] memory id = new int32[](users[msg.sender].boards.length);
		string[] memory title = new string[](users[msg.sender].boards.length);
		int64[] memory start = new int64[](users[msg.sender].boards.length);
		int64[] memory finish = new int64[](users[msg.sender].boards.length);
		for (uint i = 0; i < users[msg.sender].boards.length; i++) {
			id[i] = boards[users[msg.sender].boards[i]].id;
			title[i] = boards[users[msg.sender].boards[i]].title;
			start[i] = boards[users[msg.sender].boards[i]].start;
			finish[i] = boards[users[msg.sender].boards[i]].finish;
		}
		return (id, title, start, finish);
	}*/
	
	function getBoard(int32 id) public view returns (string memory, int64, int64, int32[] memory, address[] memory) {
		require (boards[id].usersSet[msg.sender]);
		Board memory b = boards[id];
		return (b.title, b.start, b.finish, b.groupsId, b.users);
	}
	
	function getBoardCard(int32 id) public view returns (string memory, int64, int64) {
		require (boards[id].usersSet[msg.sender]);
		Board memory b = boards[id];
		return (b.title, b.start, b.finish);
	}
	
	function getBoardsIndices() public view returns (int32[] memory) {
		return users[msg.sender].boards;
	}

	function getGroupsIndices(int32 boardId) public view returns (int32[] memory) {
		require (boards[boardId].usersSet[msg.sender]);
		return boards[boardId].groupsId;
	}
	
	/*function getGroup(int32 groupId) public view returns (string memory, int32[] memory, string[] memory, string[] memory, int64[] memory, int64[] memory) {
		Group memory group = groups[groupId];
		string[] memory tasksTitle = new string[](group.tasksId.length);
		string[] memory tasksDescription = new string[](group.tasksId.length);
		int64[] memory tasksStart = new int64[](group.tasksId.length);
		int64[] memory tasksFinish = new int64[](group.tasksId.length);
		for (uint i = 0; i < group.tasksId.length; i++) {
			tasksTitle[i] = tasks[group.tasksId[i]].title;
			tasksDescription[i] = tasks[group.tasksId[i]].description;
			tasksStart[i] = tasks[group.tasksId[i]].start;
			tasksFinish[i] = tasks[group.tasksId[i]].finish;
		}
		return (group.title, group.tasksId);
	}*/
	
	function getGroup(int32 groupId) public view returns(string memory, int32[] memory){
		int32 boardId = groups[groupId].boardId;
		require (boards[boardId].usersSet[msg.sender]);
		Group memory group = groups[groupId];
		return (group.title, group.tasksId);
	}
	
	function getTask(int32 taskId) public view returns (string memory, string memory, int64, int64, int32, int32, address[] memory) {
		int32 boardId = tasks[taskId].boardId;
		require (boards[boardId].usersSet[msg.sender]);
		Task memory task = tasks[taskId];
		return (task.title, task.description, task.start, task.finish, task.groupId, task.boardId, task.users);
	}
	
	function removeBoardFromUser(address userId, int32 boardId) public {
		User storage user = users[userId];
		bool found = false;
		uint index = 0;
		for (uint i = 0; i < user.boards.length; i++) {
			if (user.boards[i] == boardId) {
				index = i;
				found = true;
				break;
			}
		}
		if (found) {
			for (uint i = index + 1; i < user.boards.length; i++) {
				user.boards[i - 1] = user.boards[i];
			}
			delete user.boards[user.boards.length - 1];
			user.boards.length--;
		}
	}
	
	function removeUserFromBoard(address userId, int32 boardId) public {
		Board storage board = boards[boardId];
		board.usersSet[userId] = false;
		bool found = false;
		uint index = 0;
		for (uint i = 0; i < board.users.length; i++) {
			if (board.users[i] == userId) {
				index = i;
				found = true;
				break;
			}
		}
		if (found) {
			for (uint i = index + 1; i < board.users.length; i++) {
				board.users[i - 1] = board.users[i];
			}
			delete board.users[board.users.length - 1];
			board.users.length--;
		}
	}
	
	function addTaskParticipant(int32 taskId, address user) public {
		int32 boardId = tasks[taskId].boardId;
		require (boards[boardId].usersSet[msg.sender]);
		Task storage task = tasks[taskId];
		if (users[user].valid && !task.usersSet[user]) {
			task.usersSet[user] = true;
			task.users.push(user);
			addBoardParticipant(boardId, user);
			emit taskParticipantAdded(users[user].nick);
		}
		else {
			emit taskParticipantAdded("");
		}
	}
	
	function removeTaskUser (int32 taskId, address userId) public {
		int32 boardId = tasks[taskId].boardId;
		require (boards[boardId].usersSet[msg.sender]);
		Task storage task = tasks[taskId];
		if (task.usersSet[userId]) {
			task.usersSet[userId] = false;
			bool found = false;
			uint index = 0;
			for (uint k = 0; k < task.users.length; k++) {
				if (task.users[k] == userId) {
					index = k;
					found = true;
					break;
				}
			}
			if (found) {
				for (uint k = index + 1; k < task.users.length; k++) {
					task.users[k - 1] = task.users[k];
				}
				delete task.users[task.users.length - 1];
				task.users.length--;
			}
		}
	}
	
	function removeTaskUsersOfBoard (int32 boardId, address userId) public {
		require (boards[boardId].usersSet[msg.sender]);
		Board storage board = boards[boardId];
		for (uint i = 0; i < board.groupsId.length; i++) {
			Group storage group = groups[board.groupsId[i]];
			for (uint j = 0; j < group.tasksId.length; j++) {
				removeTaskUser(group.tasksId[j], userId);
			}
		}
	}
	 
	function leaveBoard(int32 id) public {
		removeTaskUsersOfBoard(id, msg.sender);
		removeBoardFromUser(msg.sender, id);
		removeUserFromBoard(msg.sender, id);
		emit boardLeft(true);
	}
	
	function eraseBoard(int32 id) public {
		Board storage board = boards[id];
		if (board.usersSet[msg.sender]) {
			for (uint i = 0; i < board.users.length; i++) {
				removeBoardFromUser(board.users[i], id);
			}
			delete boards[id];
			emit boardRemoved(true);
		}
		else {
			emit boardRemoved(false);
		}
	}
}