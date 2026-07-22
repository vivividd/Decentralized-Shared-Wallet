import { BrowserProvider, Contract, Interface, isAddress, parseEther, formatEther } from "https://cdn.jsdelivr.net/npm/ethers@6.13.5/+esm";

const ABI = [
  "function getOwners() view returns (address[])",
  "function requiredApprovals() view returns (uint16)",
  "function getTransactionCount() view returns (uint256)",
  "function getTransaction(uint256) view returns (tuple(address to,uint256 value,bytes data,bool executed,uint256 approvalCount))",
  "function getConfirmations(uint256) view returns (address[])",
  "function approved(uint256,address) view returns (bool)",
  "function submitTransaction(address,uint256,bytes) returns (uint256)",
  "function approveTransaction(uint256)",
  "function revokeApproval(uint256)",
  "function executeTransaction(uint256)",
  "function addOwner(address)",
  "function removeOwner(address)",
  "function changeRequirement(uint16)"
];

let provider;
let signer;
let contract;
let account;

const $ = (id) => document.getElementById(id);
const short = (value) => `${value.slice(0, 6)}…${value.slice(-4)}`;
const setStatus = (message, type = "") => { $("status").textContent = message; $("status").className = `status ${type}`; };

function walletAddress() {
  const value = $("walletAddress").value.trim();
  if (!isAddress(value)) throw new Error("Enter a valid deployed wallet address.");
  return value;
}

function explain(error) {
  return error?.shortMessage || error?.reason || error?.info?.error?.message || error?.message || "Transaction failed.";
}

async function connect() {
  if (!window.ethereum) throw new Error("Install MetaMask or another browser wallet first.");
  provider = new BrowserProvider(window.ethereum);
  await provider.send("eth_requestAccounts", []);
  signer = await provider.getSigner();
  account = await signer.getAddress();
  $("account").textContent = short(account);
  $("connectButton").textContent = short(account);
  setStatus("Wallet connected.", "success");
}

async function load() {
  if (!provider) await connect();
  contract = new Contract(walletAddress(), ABI, signer || provider);
  const [owners, threshold, count, balance] = await Promise.all([
    contract.getOwners(), contract.requiredApprovals(), contract.getTransactionCount(), provider.getBalance(contract.target)
  ]);
  $("balance").textContent = `${formatEther(balance)} ETH`;
  $("threshold").textContent = `${threshold} of ${owners.length}`;
  $("ownerCount").textContent = owners.length;
  $("newRequirement").max = owners.length;
  $("walletSection").classList.remove("hidden");
  await refreshTransactions(Number(count));
  setStatus(`Loaded ${short(contract.target)}.`, "success");
}

async function send(label, action) {
  try {
    setStatus(`${label}…`);
    const tx = await action();
    await tx.wait();
    await load();
    setStatus(`${label} confirmed.`, "success");
  } catch (error) { setStatus(explain(error), "error"); }
}

async function refreshTransactions(count) {
  const container = $("transactions");
  if (!count) { container.innerHTML = '<p class="hint">No transactions yet.</p>'; return; }
  const rows = await Promise.all(Array.from({ length: count }, async (_, id) => {
    const [tx, confirmations, mine] = await Promise.all([
      contract.getTransaction(id), contract.getConfirmations(id), contract.approved(id, account)
    ]);
    const enough = Number(tx.approvalCount) >= Number($("threshold").textContent.split(" ")[0]);
    const buttons = tx.executed
      ? '<span class="done">Executed</span>'
      : `<button class="button small" data-action="approve" data-id="${id}" ${mine ? "disabled" : ""}>Approve</button>
         <button class="button small" data-action="revoke" data-id="${id}" ${mine ? "" : "disabled"}>Revoke</button>
         <button class="button small primary" data-action="execute" data-id="${id}" ${enough ? "" : "disabled"}>Execute</button>`;
    return `<article class="transaction"><div class="transaction-head"><strong>#${id}</strong><span>${tx.executed ? "Executed" : "Pending"}</span></div>
      <div class="transaction-meta"><span>To <code>${short(tx.to)}</code></span><span>${formatEther(tx.value)} ETH</span><span>${tx.approvalCount} approvals</span></div>
      <div class="hint">Confirmed by: ${confirmations.length ? confirmations.map(short).join(", ") : "nobody"}</div><div class="actions">${buttons}</div></article>`;
  }));
  container.innerHTML = rows.reverse().join("");
}

$("connectButton").onclick = () => connect().catch((error) => setStatus(explain(error), "error"));
$("loadButton").onclick = () => load().catch((error) => setStatus(explain(error), "error"));
$("refreshButton").onclick = () => load().catch((error) => setStatus(explain(error), "error"));

$("transactionForm").onsubmit = async (event) => {
  event.preventDefault();
  try {
    const to = $("recipient").value.trim();
    if (!isAddress(to)) throw new Error("Enter a valid recipient address.");
    const data = $("data").value.trim() || "0x";
    if (!/^0x([0-9a-f]{2})*$/i.test(data)) throw new Error("Calldata must be valid hex.");
    await send("Submitting transaction", () => contract.submitTransaction(to, parseEther($("value").value || "0"), data));
  } catch (error) { setStatus(explain(error), "error"); }
};

async function proposeAdmin(functionName, args) {
  const data = new Interface(ABI).encodeFunctionData(functionName, args);
  await send("Submitting administration transaction", () => contract.submitTransaction(contract.target, 0, data));
}

$("addOwnerForm").onsubmit = (event) => { event.preventDefault(); proposeAdmin("addOwner", [$("newOwner").value.trim()]).catch((error) => setStatus(explain(error), "error")); };
$("removeOwnerForm").onsubmit = (event) => { event.preventDefault(); proposeAdmin("removeOwner", [$("removeOwner").value.trim()]).catch((error) => setStatus(explain(error), "error")); };
$("requirementForm").onsubmit = (event) => { event.preventDefault(); proposeAdmin("changeRequirement", [$("newRequirement").value]).catch((error) => setStatus(explain(error), "error")); };

$("transactions").onclick = (event) => {
  const button = event.target.closest("button[data-action]");
  if (!button) return;
  const id = Number(button.dataset.id);
  const method = { approve: "approveTransaction", revoke: "revokeApproval", execute: "executeTransaction" }[button.dataset.action];
  send(`${button.dataset.action} transaction`, () => contract[method](id));
};

if (localStorage.getItem("sharedWalletAddress")) $("walletAddress").value = localStorage.getItem("sharedWalletAddress");
$("walletAddress").addEventListener("change", () => localStorage.setItem("sharedWalletAddress", $("walletAddress").value.trim()));
