const DB_NAME = 'md-notes-db';
const DB_VERSION = 1;

let db;

export const openDB = () => {
  return new Promise((resolve, reject) => {
    const request = indexedDB.open(DB_NAME, DB_VERSION);

    request.onupgradeneeded = (event) => {
      db = event.target.result;
      db.createObjectStore('projects', { keyPath: 'id' });
      db.createObjectStore('folders', { keyPath: 'id' });
      db.createObjectStore('notes', { keyPath: 'id' });
    };

    request.onsuccess = (event) => {
      db = event.target.result;
      resolve(db);
    };

    request.onerror = (event) => {
      reject('Error opening IndexedDB');
    };
  });
};

export const getStore = (storeName, mode) => {
  const tx = db.transaction(storeName, mode);
  return tx.objectStore(storeName);
};
