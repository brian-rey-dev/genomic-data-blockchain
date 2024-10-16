// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/// @title DataStorage Contract
/// @notice Manages the registration and storage of genetic data references for patients.
/// @dev Patients can register and update their genetic data, and authorized contracts can retrieve the data.
contract DataStorage is Initializable {
    /// @notice Emitted when genetic data is registered by a patient.
    /// @param patient The address of the patient registering the data.
    /// @param sampleId The unique identifier of the genetic sample.
    event DataRegistered(address indexed patient, uint256 indexed sampleId);

    /// @notice Emitted when genetic data is updated by a patient.
    /// @param patient The address of the patient updating the data.
    /// @param sampleId The unique identifier of the genetic sample.
    event DataUpdated(address indexed patient, uint256 indexed sampleId);

    /// @notice Mapping from sample ID to genetic data reference.
    mapping(uint256 => string) private geneticDataBySampleId;

    /// @notice Mapping from patient address to their sample IDs.
    mapping(address => uint256[]) private sampleIdsByPatient;

    /// @notice Mapping from sample ID to the patient who owns it.
    mapping(uint256 => address) public sampleIdToPatient;

    /// @notice Counter for assigning unique IDs to access samples.
    uint256 private sampleID;

    /// @notice The address of the AccessControl contract authorized to retrieve data.
    address public accessControlContract;

    // Custom Errors
    /// @notice Error for unauthorized access by a non-owner.
    error NotAuthorized();

    /// @notice Error for attempting to register an already registered sample ID.
    error SampleAlreadyRegistered();

    /// @notice Error for providing an empty data reference.
    error DataReferenceCannotBeEmpty();

    /// @notice Error for attempting to update data for a non-registered sample ID.
    error DataNotRegistered();

    /// @notice Error for unauthorized access by a non-AccessControl contract.
    error AccessControlOnly();

    /// @notice Modifier to restrict function access to the owner of the sample.
    /// @param _sampleId The unique identifier of the genetic sample.
    modifier onlyOwner(uint256 _sampleId) {
        if (sampleIdToPatient[_sampleId] != msg.sender) {
            revert NotAuthorized();
        }
        _;
    }

    /// @notice Modifier to restrict function access to the AccessControl contract.
    modifier onlyAccessControl() {
        if (msg.sender != accessControlContract) {
            revert AccessControlOnly();
        }
        _;
    }

    /// @notice Initializes the contract with the AccessControl contract address.
    /// @param _accessControlContract The address of the deployed AccessControl contract.
    function initialize(address _accessControlContract) public initializer {
        if (_accessControlContract == address(0)) {
            revert AccessControlOnly();
        }
        accessControlContract = _accessControlContract;
    }

    /// @notice Retrieves the sample IDs associated with a patient.
    /// @param _patient The address of the patient.
    /// @return An array of sample IDs owned by the patient.
    function getSampleIdsByPatient(address _patient)
        external
        view
        returns (uint256[] memory)
    {
        return sampleIdsByPatient[_patient];
    }

    /// @notice Allows a patient to register their genetic data.
    /// @dev The sample ID must not have been registered before.
    /// @param _dataReference The reference to the genetic data (e.g., IPFS hash).
    function registerData(string calldata _dataReference)
        external
    {
        if (sampleIdToPatient[sampleID] != address(0)) {
            revert SampleAlreadyRegistered();
        }
        if (bytes(_dataReference).length == 0) {
            revert DataReferenceCannotBeEmpty();
        }

        geneticDataBySampleId[sampleID] = _dataReference;
        sampleIdsByPatient[msg.sender].push(sampleID);
        sampleIdToPatient[sampleID] = msg.sender;

        emit DataRegistered(msg.sender, sampleID);

        sampleID++;
    }

    /// @notice Allows a patient to update their existing genetic data.
    /// @dev Only the owner of the sample can update its data.
    /// @param _sampleId The unique identifier of the genetic sample.
    /// @param _dataReference The new reference to the genetic data.
    function updateData(uint256 _sampleId, string calldata _dataReference)
        external
        onlyOwner(_sampleId)
    {
        if (bytes(geneticDataBySampleId[_sampleId]).length == 0) {
            revert DataNotRegistered();
        }
        if (bytes(_dataReference).length == 0) {
            revert DataReferenceCannotBeEmpty();
        }

        geneticDataBySampleId[_sampleId] = _dataReference;

        emit DataUpdated(msg.sender, _sampleId);
    }

    /// @notice Retrieves the genetic data reference for a given sample ID.
    /// @dev Only callable by the AccessControl contract.
    /// @param _sampleId The unique identifier of the genetic sample.
    /// @return The genetic data reference string.
    function getData(uint256 _sampleId)
        external
        view
        onlyAccessControl
        returns (string memory)
    {
        string memory dataReference = geneticDataBySampleId[_sampleId];
        if (bytes(dataReference).length == 0) {
            revert DataNotRegistered();
        }
        return dataReference;
    }
}
