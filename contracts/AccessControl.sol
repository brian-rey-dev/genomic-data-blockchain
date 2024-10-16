// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "./DataStorage.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/// @title AccessControl Contract
/// @notice Manages access requests and permissions for genetic data stored in DataStorage.
/// @dev Uses modifiers for access control and follows Solidity best practices.
contract AccessControl is Initializable, ReentrancyGuard {
    /// @notice Reference to the DataStorage contract.
    DataStorage private dataStorage;

    /// @notice Enum representing the status of an access request.
    enum RequestStatus {
        PENDING,
        REJECTED,
        ACCEPTED,
        CANCELLED
    }

    /// @notice Counter for assigning unique IDs to access requests.
    uint256 private requestID;

    /// @notice Struct representing an access request.
    struct AccessRequest {
        RequestStatus status;
        uint256 id;
        uint256 sampleId;
        uint256 amountOffered;
        address researcher;
    }

    /// @notice Mapping from request ID to AccessRequest.
    mapping(uint256 => AccessRequest) private requests;

    /// @notice Mapping from request key to request ID.
    mapping(bytes32 => uint256) private requestIndexBySampleAndResearcher;

    /// @notice Mapping from researcher address to their request IDs.
    mapping(address => uint256[]) private requestsIDsByResearcher;

    /// @notice Mapping from patient address to request IDs related to their samples.
    mapping(address => uint256[]) private requestsIDsByPatient;

    /// @notice Error indicating that a request already exists.
    error RequestAlreadyExists();

    /// @notice Error indicating that a request does not exist.
    error RequestDoesNotExist();

    /// @notice Error indicating that the caller is not authorized to perform the action.
    error NotAuthorized();

    /// @notice Error indicating that the request is invalid.
    error InvalidRequest();

    /// @notice Error indicating that the payment transfer failed.
    error PaymentFailed();

    /// @notice Emitted when a new access request is created.
    /// @param requestId The unique ID of the access request.
    /// @param researcher The address of the researcher making the request.
    /// @param sampleId The ID of the sample requested.
    /// @param amountOffered The amount of Ether offered for access.
    event AccessRequestCreated(
        uint256 indexed requestId,
        address indexed researcher,
        uint256 indexed sampleId,
        uint256 amountOffered
    );

    /// @notice Emitted when the status of an access request is changed.
    /// @param requestId The unique ID of the access request.
    /// @param newStatus The new status of the access request.
    event AccessRequestStatusChanged(
        uint256 indexed requestId,
        RequestStatus newStatus
    );

    /// @notice Modifier to check if the request exists.
    /// @param _requestId The ID of the access request.
    modifier requestExists(uint256 _requestId) {
        if (requests[_requestId].id == 0) {
            revert RequestDoesNotExist();
        }
        _;
    }

    /// @notice Modifier to check if the caller is the patient who owns the sample.
    /// @param _sampleId The ID of the sample.
    modifier onlyPatient(uint256 _sampleId) {
        if (dataStorage.sampleIdToPatient(_sampleId) != msg.sender) {
            revert NotAuthorized();
        }
        _;
    }

    /// @notice Modifier to check if the caller is the researcher who made the request.
    /// @param _requestId The ID of the access request.
    modifier onlyResearcher(uint256 _requestId) {
        if (requests[_requestId].researcher != msg.sender) {
            revert NotAuthorized();
        }
        _;
    }

    /// @notice Initializes the contract with the DataStorage contract address.
    /// @param _dataStorage The address of the deployed DataStorage contract.
    function initialize(address _dataStorage) public initializer {
        if (_dataStorage == address(0)) {
            revert InvalidRequest();
        }
        dataStorage = DataStorage(_dataStorage);
        requestID = 1; // Initialize the request ID counter
    }

    /// @notice Allows a researcher to create a new access request for a sample.
    /// @dev The researcher must send Ether equal to the amount offered.
    /// @param _sampleId The ID of the sample the researcher wants to access.
    function createAccessRequest(uint256 _sampleId) external payable {
        bytes32 requestKey = generateRequestKey(_sampleId, msg.sender);

        if (requestIndexBySampleAndResearcher[requestKey] != 0) {
            revert RequestAlreadyExists();
        }

        // Ensure the sample exists
        address patient = dataStorage.sampleIdToPatient(_sampleId);
        if (patient == address(0)) {
            revert InvalidRequest();
        }

        // Store the access request
        requests[requestID] = AccessRequest(
            RequestStatus.PENDING,
            requestID,
            _sampleId,
            msg.value,
            msg.sender
        );

        requestIndexBySampleAndResearcher[requestKey] = requestID;
        requestsIDsByResearcher[msg.sender].push(requestID);
        requestsIDsByPatient[patient].push(requestID);

        emit AccessRequestCreated(requestID, msg.sender, _sampleId, msg.value);

        requestID++;
    }

    /// @notice Allows the patient to accept or reject an access request.
    /// @dev Transfers Ether to the patient or refunds the researcher based on the action.
    /// @param _requestId The ID of the access request.
    /// @param _newStatus The new status to set (ACCEPTED or REJECTED).
    function modifyRequestStatus(uint256 _requestId, RequestStatus _newStatus)
        external
        requestExists(_requestId)
        onlyPatient(requests[_requestId].sampleId)
        nonReentrant
    {
        AccessRequest storage request = requests[_requestId];

        require(
            _newStatus == RequestStatus.ACCEPTED ||
                _newStatus == RequestStatus.REJECTED,
            "Invalid status"
        );

        request.status = _newStatus;
        emit AccessRequestStatusChanged(_requestId, _newStatus);

        if (_newStatus == RequestStatus.ACCEPTED) {
            // Transfer the amount offered to the patient
            (bool success, ) = msg.sender.call{value: request.amountOffered}(
                ""
            );
            if (!success) {
                revert PaymentFailed();
            }
        } else if (_newStatus == RequestStatus.REJECTED) {
            // Refund the researcher
            (bool success, ) = request.researcher.call{
                value: request.amountOffered
            }("");
            if (!success) {
                revert PaymentFailed();
            }
        }
    }

    /// @notice Allows an authorized researcher to retrieve the genetic data reference.
    /// @param _requestId The ID of the access request.
    /// @return dataReference The genetic data reference string.
    function retrieveData(uint256 _requestId)
        external
        view
        requestExists(_requestId)
        onlyResearcher(_requestId)
        returns (string memory dataReference)
    {
        AccessRequest storage request = requests[_requestId];

        if (request.status != RequestStatus.ACCEPTED) {
            revert NotAuthorized();
        }

        dataReference = dataStorage.getData(request.sampleId);
    }

    /// @notice Generates a unique key for the access request based on sample ID and researcher address.
    /// @param _sampleId The ID of the sample.
    /// @param _researcher The address of the researcher.
    /// @return The generated request key.
    function generateRequestKey(uint256 _sampleId, address _researcher)
        private
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(_sampleId, _researcher));
    }
}
